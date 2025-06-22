//
//  BRResponse.swift
//
//
//  Created by BR on 2024/12/4.
//

import Foundation


/// `BRResponse` 封裝 Request、Response 等
///
/// # 功能
///
/// - 提供 Log 打印
///
public class BRResponse: CustomStringConvertible {
    public var request: BRRequest
    public var duration: TimeInterval = 0
    public var retry: Int = 0
    
    public var statusCode: Int = 0
    public var response: URLResponse?
    public var responseHeaders: [String: String] = [:]
    public var data: Data = Data()
    
    
    public init(request: BRRequest) {
        self.request = request
    }
    
    
    public var description: String {
        var description = "\(request)\n"
        description += "Response:\n"
        description += "    statusCode: \(statusCode)\n"
        description += "    duration: \(duration)\n"
        description += "    retry: \(retry)\n"
        description += "    response: \(response?.debugDescription.count ?? 0)\n"
        description += "    data: \(data.count)\n"
        return description
    }

    
}
