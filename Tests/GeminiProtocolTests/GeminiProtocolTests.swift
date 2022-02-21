//
// GeminiProtocolTests.swift
//
// Copyright © 2022 Izzy Fraimow. All rights reserved.
//

@_predatesConcurrency import XCTest
@testable import GeminiProtocol

enum GeminiHeaders {
    static let successWithGeminiContent = GeminiResponseHeader(status: .success, meta: "text/gemini")
}

enum GeminiBodies {
    static let genericBody = """
        # Gemini
        
        This is a response body
        
        ## Title 2
        """
}

final class GeminiProtocolTests: XCTestCase {
    let server = GeminiTestServer()
    
    override func setUp() async throws {
        URLProtocol.registerClass(GeminiProtocol.self)
    }
    
    func testRequest() async throws {
        await server.start(header: GeminiHeaders.successWithGeminiContent, body: GeminiBodies.genericBody)

//        let url = URL(string: "gemini://localhost:1965")!
        let url = URL(string: "gemini://geddit.glv.one")!
        let client = try GeminiClient(request: URLRequest(url: url), debug: false)
        let (header, maybeData) = try await client.start()
        
        XCTAssertEqual(header, GeminiHeaders.successWithGeminiContent)
        
        let data = try XCTUnwrap(maybeData)
        let string = try XCTUnwrap(String(data: data, encoding: .utf8))
        
        XCTAssertEqual(string, GeminiBodies.genericBody)
    }
}
