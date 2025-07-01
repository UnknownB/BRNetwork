//
//  BRNetworkError.swift
//  BRNetwork
//
//  Created by BR on 2025/6/15.
//

import Foundation
import BRFoundation


public enum BRNetworkError: Error, CustomDebugStringConvertible {
    /// App 端錯誤，例如 request 構造錯誤、JSON encode 問題
    case client(underlying: Error)
    
    /// 無法建立連線，或無法獲得任何回應（URLError 轉出）
    case network(URLError)
    
    /// 收到 Response，但 statusCode 非 2xx，並且附帶錯誤資料
    case server(statusCode: Int, data: Data?, message: String?)

    /// 回傳的 response 非 HTTPURLResponse，應該是嚴重異常
    case unexpectedResponse

    /// 資料解析錯誤
    case decoding(Error)
    
    /// 缺少必要欄位
    case missingKey(String)

    /// 其他未分類錯誤
    case unknown(Error)
    
    
    public var debugDescription: String {
        switch self {
        case let .client(error):
            return "[ClientError] \(error)"
        case let .network(urlError):
            return "[NetworkError] \(urlError)"
        case let .server(code, _, message):
            return "[ServerError] \(code) – \(message ?? "No message")"
        case .unexpectedResponse:
            return "[UnexpectedResponse] Response is not HTTPURLResponse"
        case let .decoding(error):
            return "[DecodingError] \(error)"
        case let .missingKey(key):
            return "[MissingKey] \(key)"
        case let .unknown(error):
            return "[UnknownError] \(error)"
        }
    }
}

