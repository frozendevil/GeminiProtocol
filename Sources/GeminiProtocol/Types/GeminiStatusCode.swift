//
// GeminiStatusCode.swift
//
// Copyright © 2022 Izzy Fraimow. All rights reserved.
//

public enum GeminiStatusCode: Int, RawRepresentable, Sendable {
    case input = 10
    case sensitiveInput
    
    case success = 20
    
    case redirectTemporary = 30
    case redirectPermanent
    
    case temporaryFailure = 40
    case serverUnavailable
    case cgiError
    case proxyError
    case slowDown
    
    case permanentFailure = 50
    case notFound
    case gone
    case proxyRequestRefused
    case badRequest
    
    case clientCertificateRequired = 60
    case certificateNotAuthorized
    case certificateNotValid
    
    public var isSuccess: Bool {
        self == .success
    }
}
