//
// GeminiClientError.swift
//
// Copyright © 2022 Izzy Fraimow. All rights reserved.
//

enum GeminiClientError: Error {
    case initializationError(String)
    case transactionError(String)
    case cancelled
    case unknown
}
