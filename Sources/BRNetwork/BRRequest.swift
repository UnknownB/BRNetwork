//
//  BRRequest.swift
//
//
//  Created by BR on 2024/12/4.
//

import Foundation
import BRFoundation


/// `BRRequest` 封裝網路請求資訊
///
///  # 功能
///
///  - 提供 DSL 語法建立
///  - 提供 Log 打印
///  - Release 模式下隱藏 url、header 資訊
///
///  # 範例
///
///  ``` swift
///  BRRequest.get(url)
///      .name("fetch User")
///  ```
public class BRRequest: CustomStringConvertible {
        
    public enum Method: String {
        case get, post, put, patch, delete
    }
        
    public enum BodyType {
        case none, json, raw
    }
    
    public let url: URL
    public var method: Method
    public var bodyType: BodyType
    
    public var name: String = ""
    public var headers: [String: String] = [:]
    public var queryParams: [String: String] = [:]
    public var bodyParams: [String: Any] = [:]
    public var timeout: TimeInterval = 30
    
    
    public init(_ url: URL, method: Method, bodyType: BodyType) {
        self.url = url
        self.method = method
        self.bodyType = bodyType
    }
    
    
    public func urlRequest() throws -> URLRequest {
        guard let url = url.br.appendingQuery(from: queryParams) else {
            fatalError("Invalid query params")
        }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        request.timeoutInterval = timeout
        
        switch bodyType {
        case .json:
            request.httpBody = try? JSONSerialization.data(withJSONObject: bodyParams)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        case .raw:
            let raws = bodyParams.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
            request.httpBody = raws.data(using: .utf8)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        case .none: break
        }
        return request
    }

    
    /// 格式化 Request 的詳細資訊
    public var description: String {
        var description = "Request:\n"
        description += "    Name: \(name)\n"
        
        #if DEBUG
        description += "    URL: \(url.absoluteString)\n"
        #else
        description += "    URL: ****\(url.lastPathComponent)\n"
        #endif
        
        description += "    Method: \(method.rawValue)\n"
        
        #if DEBUG
        description += "    Headers: \n"
        headers.forEach { key, value in
            description += "        \(key): \(value)\n"
        }
        #endif
        
        description += "    Query: \n"
        queryParams.forEach { key, value in
            description += "        \(key): \(value)\n"
        }

        description += "    Body: \n"
        bodyParams.forEach { key, value in
            description += "        \(key): \(value)\n"
        }
        return description
    }

    
}


// MARK: - DSL


public extension BRRequest {
    

    @discardableResult
    func query(_ key: String, _ value: CustomStringConvertible?) -> Self {
        if let value = value {
            queryParams[key] = "\(value)"
        }
        return self
    }
    
    
    @discardableResult
    func queries(_ params: [String: CustomStringConvertible?]) -> Self {
        for (key, value) in params {
            if let value = value {
                queryParams[key] = "\(value)"
            }
        }
        return self
    }

    
    @discardableResult
    func header(_ key: String, _ value: String?) -> Self {
        if let value = value {
            headers[key] = value
        }
        return self
    }
    
    
    @discardableResult
    func headers(_ params: [String: String?]) -> Self {
        for (key, value) in params {
            if let value = value {
                headers[key] = value
            }
        }
        return self
    }

    
    @discardableResult
    func body(_ key: String, _ value: Any?) -> Self {
        if let value = value {
            bodyParams[key] = value
        }
        return self
    }
    
    
    @discardableResult
    func bodies(_ params: [String: Any?]) -> Self {
        for (key, value) in params {
            if let value = value {
                bodyParams[key] = value
            }
        }
        return self
    }
    
    
    @discardableResult
    func name(_ name: String) -> Self {
        self.name = name
        return self
    }
    
    
    @discardableResult
    func method(_ method: Method) -> Self {
        self.method = method
        return self
    }
    
    
    @discardableResult
    func bodyType(_ bodyType: BodyType) -> Self {
        self.bodyType = bodyType
        return self
    }
    
    
}


// MARK: - 快速建立


public extension BRRequest {
    
    
    static func get(_ url: URL) -> BRRequest {
        BRRequest(url, method: .get, bodyType: .none)
    }
    
    
    static func postJSON(_ url: URL) -> BRRequest {
        BRRequest(url, method: .post, bodyType: .json)
    }
    
    
    static func postForm(_ url: URL) -> BRRequest {
        BRRequest(url, method: .post, bodyType: .raw)
    }
    
    
    static func putJSON(_ url: URL) -> BRRequest {
        BRRequest(url, method: .put, bodyType: .json)
    }
    

    static func patchJSON(_ url: URL) -> BRRequest {
        BRRequest(url, method: .patch, bodyType: .json)
    }
    

    static func delete(_ url: URL) -> BRRequest {
        BRRequest(url, method: .delete, bodyType: .none)
    }
    
    
}
