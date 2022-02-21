//
// GeminiResponseHeader.swift
//
// Copyright © 2022 Izzy Fraimow. All rights reserved.
//

import Network

public struct GeminiResponseHeader: Equatable, Sendable {
    let status: GeminiStatusCode
    let meta: String
}

extension String {
    public init(geminiResponseHeader: GeminiResponseHeader) {
        self.init("\(geminiResponseHeader.status.rawValue) \(geminiResponseHeader.meta)\r\n")
    }
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
