//
// GeminiURLResponse.swift
//
// Copyright © 2022 Izzy Fraimow. All rights reserved.
//

import Foundation

let StatusCodeKey = "StatusCodeKey"
let MetaKey = "MetaKey"

public class GeminiURLResponse: URLResponse {
    var statusCode: GeminiStatusCode
    var meta: String
    
    class public override var supportsSecureCoding: Bool {
        true
    }
    
    public override var mimeType: String? {
        statusCode.isSuccess ? meta : nil
    }
    
    init(url: URL, expectedContentLength: Int, statusCode: GeminiStatusCode, meta: String) {
        self.statusCode = statusCode
        self.meta = meta
        
        let mimeType = statusCode.isSuccess ? meta : nil
        super.init(url: url, mimeType: mimeType, expectedContentLength: expectedContentLength, textEncodingName: nil)
    }
    
    required init(_ response: GeminiURLResponse) {
        self.statusCode = response.statusCode
        self.meta = response.meta
        
        super.init(
            url: response.url!,
            mimeType: response.mimeType,
            expectedContentLength: Int(response.expectedContentLength),
            textEncodingName: response.textEncodingName
        )
    }
    
    required init?(coder: NSCoder) {
        let statusCodeValue = coder.decodeInteger(forKey: StatusCodeKey)
        self.statusCode = GeminiStatusCode(rawValue: statusCodeValue)!
        
        let meta = coder.decodeObject(of: NSString.self, forKey: MetaKey)! as String
        self.meta = meta
        
        super.init(coder: coder)
    }
    
    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        
        coder.encode(statusCode.rawValue, forKey: StatusCodeKey)
        coder.encode(meta, forKey: MetaKey)
    }
    
    override public func copy() -> Any {
        return type(of:self).init(self)
    }
    
    override public func copy(with zone: NSZone? = nil) -> Any {
        return type(of:self).init(self)
    }
}
