//
// HeaderParser.swift
//
// Copyright © 2022 Izzy Fraimow. All rights reserved.
//

import Network

enum ASCII {
    static let newline = UInt8(ascii: "\n")
    static let carriageReturn = UInt8(ascii: "\r")
}

enum ParserState<T> {
    case ready
    case inProgress
    case succeeded(T)
    case failed
}

protocol Parser {
    associatedtype ParseType
    
    var expectedRemainingLength: Int { get }
    var maximumLength: Int { get }
    var state: ParserState<ParseType> { get }
    var succeeded: Bool { get }
    
    /// Attempts to construct `ParseType` given `buffer`.
    /// Returns the number of bytes consumed.
    func read(_ buffer: UnsafeMutableRawBufferPointer) -> Int
}

extension Parser {
    var succeeded: Bool {
        switch state {
        case .succeeded(_): return true
        default: return false
        }
    }
    
    func result() -> ParseType {
        guard case .succeeded(let result) = state else {
            fatalError("`result` is a convenience for `succeeded` parsers only. Current state is \(state)")
        }
        
        return result
    }
    
    var maximumLength: Int {
        expectedRemainingLength
    }
    
    /// Returns whether the consume was successful or not
    func consume(_ framer: NWProtocolFramer.Instance) -> Bool {
        if succeeded { return true }
        
        _ = framer.parseInput(minimumIncompleteLength: expectedRemainingLength, maximumLength: maximumLength) { (buffer, isComplete) -> Int in
            guard let buffer = buffer else { return 0 }
            let bytesConsumed = self.read(buffer)
            
            return bytesConsumed
        }
        
        return succeeded
    }
}

class StatusCodeParser: Parser {
    private(set) var expectedRemainingLength = 2
    private(set) var state = ParserState<GeminiStatusCode>.ready
    
    func read(_ buffer: UnsafeMutableRawBufferPointer) -> Int {
        state = .inProgress
        
        guard buffer.count == expectedRemainingLength else {
            state = .failed
            return 0
        }
        
        guard
            let string = String(bytes: buffer, encoding: .utf8),
            let value = Int(string, radix: 10),
            let status = GeminiStatusCode(rawValue: value) else {
                state = .failed
                return 0
            }
        
        state = .succeeded(status)
        return expectedRemainingLength
    }
}

class SpaceParser: Parser {
    private(set) var expectedRemainingLength = 1
    private(set) var state = ParserState<()>.ready
    
    func read(_ buffer: UnsafeMutableRawBufferPointer) -> Int {
        state = .inProgress
        
        guard buffer.count == 1 else {
            state = .failed
            return 0
        }
        
        guard let data = buffer.first, data == 0x20 else {
            state = .failed
            return 0
        }
        
        state = .succeeded(())
        return 1
    }
}

class MetaParser: Parser {
    private(set) var expectedRemainingLength = 2
    private(set) var state = ParserState<String>.ready
    private(set) var maximumLength = Int.max
    
    private let endLength = 2 // <CR><LF>
    
    func read(_ buffer: UnsafeMutableRawBufferPointer) -> Int {
        state = .inProgress
        
        guard buffer.count >= endLength else {
            state = .failed
            return 0
        }
        
        guard let lastChar = buffer.last, lastChar == ASCII.newline else {
            // Buffer does not end in <LF>, try to get more bytes
            expectedRemainingLength = buffer.count + 1
            state = .failed
            return 0
        }
        
        let nextToLastIndex = buffer.index(before: buffer.count - 1)
        let nextToLastChar = buffer[nextToLastIndex]
        guard nextToLastChar == ASCII.carriageReturn else {
            // Buffer does not end in <CR><LF>, try to get more bytes
            expectedRemainingLength = buffer.count + 2
            state = .failed
            return 0
        }
        
        guard let string = String(bytes: buffer[..<nextToLastIndex], encoding: .utf8) else {
            state = .failed
            return 0
        }
        
        state = .succeeded(string)
        return expectedRemainingLength
    }
}

