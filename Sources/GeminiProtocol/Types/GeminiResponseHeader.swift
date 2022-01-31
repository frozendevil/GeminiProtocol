//
// GeminiResponseHeader.swift
//
// Copyright © 2022 Izzy Fraimow. All rights reserved.
//

import Network

public struct GeminiResponseHeader: Sendable {
    let status: GeminiStatusCode
    let meta: String
}

extension NWProtocolFramer.Message {
    static let responseHeaderKey = "geminiHeader"
    
    convenience init(geminiResponseHeader header: GeminiResponseHeader) {
        self.init(definition: GeminiFramer.definition)
        self[Self.responseHeaderKey] = header
    }
    
    var geminiResponseHeader: GeminiResponseHeader? {
        self[Self.responseHeaderKey] as? GeminiResponseHeader
    }
}
