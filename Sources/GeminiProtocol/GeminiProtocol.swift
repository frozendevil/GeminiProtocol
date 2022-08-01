//
// GeminiProtocol.swift
//
// Copyright © 2022 Izzy Fraimow. All rights reserved.
//

import Foundation
import Network
import os.log

public class GeminiProtocol: URLProtocol {
    static let logger = Logger(subsystem: "com.izzy.computer", category: "Protocol")
    
    var connection: GeminiClient! = nil
    
    enum ProtocolError: Error {
        case taskError(String)
    }
    
    public override class func canInit(with request: URLRequest) -> Bool {
        Self.logger.debug("Triaging request: \(request)")
        
        guard let url = request.url, let scheme = url.scheme else { return false }
        
        let normalizedScheme = scheme.lowercased()
        
        guard normalizedScheme == "gemini" else { return false }
        
        Self.logger.debug("Accepted request: \(request)")
        
        return true
    }
    
    public override class func canInit(with task: URLSessionTask) -> Bool {
        guard let request = task.currentRequest else { return false }
        return canInit(with: request)
    }
    
    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    public override func startLoading() {
        Task {
            connection = try! GeminiClient(request: request)
            guard let client = client else {
                await connection.stop()
                client?.urlProtocol(self, didFailWithError: ProtocolError.taskError("URLProtocol client missing"))
                return
            }
            
            do {
                let (header, maybeData) = try await connection.start()
                
                let url = request.url!
                let data = maybeData ?? Data()
                let response = GeminiURLResponse(
                    url: url,
                    expectedContentLength: data.count,
                    statusCode: header.status,
                    meta: header.meta
                )
                
                client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client.urlProtocol(self, didLoad: data)
                client.urlProtocolDidFinishLoading(self)
            } catch {
                await connection.stop()
                client.urlProtocol(self, didFailWithError: error)
            }
        }
    }
    
    public override func stopLoading() {
        Task {
            await connection?.stop()
        }
    }
}
