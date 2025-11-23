//
//  BRNetwork.swift
//
//
//  Created by BR on 2024/11/29.
//

import Foundation


public struct BRRequestOptions {
    let retryMax: UInt
    let useStatusCode: Bool
    let onCustomAPIResponseError: BRNetwork.CustomAPIResponseError?
    let onFailure: BRNetwork.FailureHandler?
    
    public init(retryMax: UInt = 3, useStatusCode: Bool = true, onCustomAPIResponseError: BRNetwork.CustomAPIResponseError? = nil, onFailure: BRNetwork.FailureHandler? = nil) {
        self.retryMax = retryMax
        self.useStatusCode = useStatusCode
        self.onCustomAPIResponseError = onCustomAPIResponseError
        self.onFailure = onFailure
    }
}


private struct BRResponseContext {
    let data: Data
    let urlResponse: URLResponse
    let startTime: Date
    let retry: Int
}


/// 提供 iOS 網路功能封裝
///
/// # 元件
///
/// ## BRNetwork
///
/// - 負責網路請求等功能操作
///
/// ## BRNetworkError
///
/// - 封裝網路請求過程的 Error
/// - 依據錯誤端區分成 client、server、network 等錯誤
///
/// ## BRRequest
///
/// - 封裝網路請求資訊
/// - 提供 DSL 語法建立
/// - 提供 Log 打印
/// - Release 模式下隱藏 url、header 資訊
///
/// ## BRResponse
///
/// - 封裝 Request、Response 等，網路請求的完整資訊
/// - 提供 Log 打印
public class BRNetwork {
    
    public typealias operationHandler = () async throws -> (Data, URLResponse)
    public typealias CustomAPIResponseError = (BRResponse) -> (errorCode: Int?, message: String?)
    public typealias FailureHandler = ((Error, BRResponse) throws -> Void)
    
    private let session: URLSession

    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    
    /// 發送網路請求，提供給用戶端實作 `fetchAPI` funcs
    ///
    /// - 特性
    ///     - 可自訂自動重試次數
    ///     - 錯誤處理封裝
    ///     - 錯誤訊息補強
    /// - 參數
    ///     - request:
    ///         - 封裝好的 `BRRequest` 物件，提供在 Log 中印出完整 request 資訊
    ///     - options:
    ///         - retryMax:
    ///             - 制定最多嘗試次數，預設為 3 次
    ///         - useStatusCode:
    ///             - 值為 true 時 statusCode 2XX 即表示成功。值為 false 時 APIResponseErrorCode != 0 表示成功，預設為 true
    ///         - onCustomAPIResponseError:
    ///             - 發生 errorStatusCode 時，用來解析 ErrorResponse 訊息 (可選)
    ///         - onFailure:
    ///             - 拋出錯誤前的 closure，可以觀看錯誤內容，以及更改錯誤 (可選)
    /// - 回傳
    ///     - `BRResponse` 此次網路請求的完整資訊，可以在 Log 中印出完整 request 與 response 資訊
    ///
    /// # 範例
    ///
    /// ``` swift
    /// import BRFoundation
    /// import BRNetwork
    /// import Foundation
    ///
    ///
    /// final class ReqResService {
    ///
    ///     static let shared = ReqResService()
    ///     private let network = BRNetwork()
    ///
    ///     var host = URL(string: "https://reqres.in/api")!
    ///
    ///
    ///     private init() {}
    ///
    ///
    ///     func request(form request: BRRequest) -> BRRequest {
    ///         request
    ///             .header("x-api-key", "reqres-free-v1")
    ///     }
    ///
    ///
    ///     func fetchAPI<T: Decodable>(_ request: BRRequest, as type: T.Type) async throws -> (BRResponse, T) {
    ///         let response = try await network.sendRequest(request, options: BRRequestOptions(
    ///             onCustomAPIResponseError: { response in
    ///                 let decoded = try? APIResponse.fromJSONData(response.data)
    ///                 return (decoded?.errorCode, decoded?.errorMessage)
    ///             },
    ///             onFailure: { error, response in
    ///                 #BRLog(.network, .error, "[Network] response error: \(error)")
    ///                 #BRLog(.network, .error, "[Network] response: \n\(response)")
    ///             }
    ///         ))
    ///         let data = try JSONDecoder().decode(T.self, from: response.data)
    ///         return (response, data)
    ///     }
    ///
    ///
    /// }
    /// ```
    @available(iOS 13.0.0, *)
    public func sendRequest(_ request: BRRequest, options: BRRequestOptions = .init()) async throws -> BRResponse {
        let response = try await performRequest(request, options: options) {
            
            if #available(iOS 15.0, *) {
                return try await self.session.data(for: request.urlRequest())
            } else {
                return try await self.session.br.data(for: request.urlRequest())
            }
        }
        return response
    }
    
    
    // MARK: - Help
    
    
    @available(iOS 13.0.0, *)
    private func performRequest(_ request: BRRequest, options: BRRequestOptions, operation: @escaping operationHandler) async throws -> BRResponse {
        let myResponse = BRResponse(request: request)
        var retry = 0
        while true {
            let startTime = Date()
            do {
                let (data, response) = try await executeRequest(operation)
                let context = BRResponseContext(data: data, urlResponse: response, startTime: startTime, retry: retry)
                try validateResponse(myResponse, options: options, context: context)
                return myResponse
            } catch {
                let duration = Date().timeIntervalSince(startTime)
                myResponse.duration = duration
                myResponse.retry = retry
                
                if case BRNetworkError.server(response: _, errorCode: _, message: _) = error {
                    try options.onFailure?(error, myResponse)
                    throw error
                }
                
                if retry < options.retryMax {
                    retry += 1
                } else {
                    try options.onFailure?(error, myResponse)
                    throw error
                }
            }
        }
    }
    
    
    @available(iOS 13.0.0, *)
    private func executeRequest(_ operation: @escaping operationHandler) async throws -> (Data, URLResponse) {
        do {
            return try await operation()
        } catch let urlError as URLError {
            throw BRNetworkError.network(urlError)
        } catch {
            throw BRNetworkError.unknown(error)
        }
    }
    
    
    private func validateResponse(_ myResponse: BRResponse, options: BRRequestOptions, context: BRResponseContext) throws {
        let duration = Date().timeIntervalSince(context.startTime)
        guard let httpURLResponse = context.urlResponse as? HTTPURLResponse else {
            throw BRNetworkError.unexpectedResponse
        }
        myResponse.response = context.urlResponse
        myResponse.data = context.data
        myResponse.duration = duration
        myResponse.retry = context.retry
        myResponse.statusCode = httpURLResponse.statusCode
        myResponse.responseHeaders = httpURLResponse.allHeaderFields.br.toStringDictionary()
        
        if options.useStatusCode {
            if myResponse.isErrorStatusCode {
                let decoded = options.onCustomAPIResponseError?(myResponse)
                throw BRNetworkError.server(response: myResponse, errorCode: decoded?.errorCode, message: decoded?.message)
            }
        } else {
            let decoded = options.onCustomAPIResponseError?(myResponse)
            if myResponse.isErrorStatusCode || (decoded?.errorCode != nil && decoded?.errorCode != 0) {
                throw BRNetworkError.server(response: myResponse, errorCode: decoded?.errorCode, message: decoded?.message)
            }
        }
    }
    
    
}
    
