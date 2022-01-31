//
// GeminiNetwork.swift
//
// Copyright © 2022 Izzy Fraimow. All rights reserved.
//

@_predatesConcurrency import Foundation
@_predatesConcurrency import Network
import os.log

public actor GeminiClient {
    private let connection: NWConnection
    private let request: GeminiRequest
    private let queue = DispatchQueue(label: "gemini client queue")
    
    init(request: URLRequest) throws {
        guard let url = request.url else { throw GeminiClientError.initializationError("No URL specified") }
        self.request = GeminiRequest(url: url)
        
        guard let urlHost = request.url?.host else { throw GeminiClientError.initializationError("No host specified") }
        let host = NWEndpoint.Host(urlHost)
        
        let urlPort = request.url?.port.map(UInt16.init) ?? 1965
        guard let port = NWEndpoint.Port(rawValue: urlPort) else { throw GeminiClientError.initializationError("Invalid port") }
        
        self.connection = NWConnection(host: host, port: port, using: .gemini(queue))
    }
    
    public func start() async throws -> (GeminiResponseHeader, Data?) {
        print("connection will start")
        
        return try await withCheckedThrowingContinuation { continuation in
            connection.stateUpdateHandler = { [weak self] state in
                guard let self = self else {
                    continuation.resume(throwing: GeminiClientError.transactionError("GeminiClient disappeared while a request was in flight"))
                    return
                }
                
                switch state {
                case .waiting(let error):
                    continuation.resume(throwing: error)
                case .ready:
                    // For some reason Swift concurrency thought there was an isolation mismatch when I tried to break this out into its own method like `setupReceive` below, so it's inline for now
                    let message = NWProtocolFramer.Message(geminiRequest: self.request)
                    let context = NWConnection.ContentContext(identifier: "GeminiRequest", metadata: [message])
                    
                    self.connection.send(
                        content: nil,
                        contentContext: context,
                        isComplete: true,
                        completion: .contentProcessed( { error in
                            if let error = error {
                                continuation.resume(throwing: error)
                                return
                            }
                        })
                    )
                case .failed(let error):
                    continuation.resume(throwing: error)
                case .cancelled:
                    continuation.resume(throwing: GeminiClientError.cancelled)
                case .setup, .preparing:
                    fallthrough
                @unknown default:
                    break
                }
            }
            
            setupReceive(continuation: continuation)
            
            connection.start(queue: queue)
        }
    }
    
    public func stop() {
        self.connection.stateUpdateHandler = nil
        self.connection.cancel()
    }
    
    private func setupReceive<T>(continuation: CheckedContinuation<T, Error>) {
        connection.receiveMessage { (data, context, isComplete, error) in
            defer {
                self.stop()
            }
            
            if let error = error {
                continuation.resume(throwing: error)
                return
            }
            
            guard isComplete else {
                continuation.resume(throwing: GeminiClientError.transactionError("Invalid Gemini response — Expected a single transaction"))
                return
            }
            
            guard
                let message = context?.protocolMetadata(definition: GeminiFramer.definition) as? NWProtocolFramer.Message,
                let header = message.geminiResponseHeader else {
                    continuation.resume(throwing: GeminiClientError.transactionError("Invalid Gemini response — Invalid header"))
                    return
                }
            
            print("header: \(header)")
            print("data: \(String(data: data ?? Data(), encoding: .utf8)!)")
            
            continuation.resume(returning: (header, data) as! T)
        }
    }
}

class GeminiFramer: NWProtocolFramerImplementation {
    static let definition = NWProtocolFramer.Definition(implementation: GeminiFramer.self)
    
    static var label = "Gemini"
    
    // Set the default behavior for most framing protocol functions.
    required init(framer: NWProtocolFramer.Instance) { }
    func start(framer: NWProtocolFramer.Instance) -> NWProtocolFramer.StartResult { return .ready }
    func wakeup(framer: NWProtocolFramer.Instance) { }
    func stop(framer: NWProtocolFramer.Instance) -> Bool { return true }
    func cleanup(framer: NWProtocolFramer.Instance) { }
    
    private var statusCode = StatusCodeParser()
    private var space = SpaceParser()
    private var meta = MetaParser()
    
    func handleInput(framer: NWProtocolFramer.Instance) -> Int {
        if !statusCode.consume(framer) {
            return statusCode.expectedRemainingLength
        }
        
        if !space.consume(framer) {
            return space.expectedRemainingLength
        }
        
        if !meta.consume(framer) {
            return meta.expectedRemainingLength
        }
        
        let status = statusCode.result()
        let metaString = meta.result()
        
        let header = GeminiResponseHeader(status: status, meta: metaString)
        let message = NWProtocolFramer.Message(geminiResponseHeader: header)
        
        _ = framer.deliverInputNoCopy(length: status == .success ? .max : 0, message: message, isComplete: true)
        
        framer.passThroughInput()
        return 0
    }
    
    func handleOutput(framer: NWProtocolFramer.Instance, message: NWProtocolFramer.Message, messageLength: Int, isComplete: Bool) {
        let request = message.geminiRequest!
        framer.writeOutput(data: request.data)
    }
}

extension NWParameters {
    static func gemini(_ queue: DispatchQueue) -> NWParameters {
        let tlsOptions = NWProtocolTLS.Options()
        sec_protocol_options_set_min_tls_protocol_version(tlsOptions.securityProtocolOptions, .TLSv12)
        sec_protocol_options_set_verify_block(tlsOptions.securityProtocolOptions, { (sec_protocol_metadata, sec_trust, sec_protocol_verify_complete) in
            // TODO: Actually handle TLS the way the spec says to. See section #4 of https://gemini.circumlunar.space/docs/specification.gmi
            sec_protocol_verify_complete(true)
        }, queue)
        
        let tcpOptions = NWProtocolTCP.Options()
        
        let parameters = NWParameters(tls: tlsOptions, tcp: tcpOptions)
        
        let options = NWProtocolFramer.Options(definition: GeminiFramer.definition)
        parameters.defaultProtocolStack.applicationProtocols.insert(options, at: 0)
        
        return parameters
    }
}
