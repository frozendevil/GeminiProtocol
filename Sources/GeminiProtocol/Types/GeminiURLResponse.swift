//
// GeminiURLResponse.swift
//
// Copyright © 2022 Izzy Fraimow. All rights reserved.
//

import Foundation

public class GeminiURLResponse: URLResponse {
    var statusCode: GeminiStatusCode
    var meta: String
    
    public override var mimeType: String? {
        statusCode.isSuccess ? meta : nil
    }
    
    init(url: URL, expectedContentLength: Int, statusCode: GeminiStatusCode, meta: String) {
        self.statusCode = statusCode
        self.meta = meta
        
        let mimeType = statusCode.isSuccess ? meta : nil
        super.init(url: url, mimeType: mimeType, expectedContentLength: expectedContentLength, textEncodingName: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
