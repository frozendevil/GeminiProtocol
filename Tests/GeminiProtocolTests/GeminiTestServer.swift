//
//  TestServer.swift
//  
//
// Copyright © 2022 Izzy Fraimow. All rights reserved.
//

@_predatesConcurrency import Foundation
@_predatesConcurrency import Network
import GeminiProtocol

/// A server for use in automated testing which accepts a connection,
/// automatically replies with the value provided in `responseBlock`,
/// and then stops itself.
actor GeminiTestServer {
    
    let port: NWEndpoint.Port
    
    private var header: GeminiResponseHeader!
    private var body: String!
    
    private let listener: NWListener
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "com.geminiprotocol.test-server", qos: .userInitiated)
    
    init(port: UInt16 = 1965) {
        let port = NWEndpoint.Port(rawValue: port)!
        self.port = port
        self.listener = try! NWListener(using: .tcp, on: port)
    }
    
    func start(header: GeminiResponseHeader, body: String) {
        self.header = header
        self.body = body
        
        listener.newConnectionHandler = handle(connection:)
        listener.start(queue: queue)
    }
    
    func stop() {
        listener.newConnectionHandler = nil
        listener.cancel()
        
        connection?.cancel()
        connection = nil
    }
    
    private func handle(connection newConnection: NWConnection) {
        guard connection == nil else {
            fatalError("`TestServer` does not support simultaneous connections")
        }
        
        connection = newConnection
        connection?.start(queue: queue)
        
        Task {
            let headerString = String(geminiResponseHeader: header)
            let headerData = headerString.data(using: .utf8)!
            await send(headerData)
            
            let bodyData = body.data(using: .utf8)!
            await send(bodyData)
        }
    }
    
    private func send(_ data: Data) async {
        return await withCheckedContinuation { continuation in
            connection?.send(content: data, completion: .contentProcessed { error in
                    if let error = error {
                        print(error)
                    }
                    continuation.resume()
                }
            )
        }
    }
}
