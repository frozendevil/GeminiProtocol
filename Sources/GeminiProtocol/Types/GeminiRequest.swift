//
// GeminiRequest.swift
//
// Copyright © 2022 Izzy Fraimow. All rights reserved.
//

import Foundation
import Network

public struct GeminiRequest: Sendable {
    let url: URL
    
    var data: Data {
        let header = "\(url.absoluteString)\r\n"
        let data = header.data(using: .utf8)!
        return data
    }
}

extension NWProtocolFramer.Message {
    static let requestKey = "GeminiRequest"
    convenience init(geminiRequest request: GeminiRequest) {
        self.init(definition: GeminiFramer.definition)
        self[Self.requestKey] = request
    }
    
    var geminiRequest: GeminiRequest? {
        self[Self.requestKey] as? GeminiRequest
    }
}
