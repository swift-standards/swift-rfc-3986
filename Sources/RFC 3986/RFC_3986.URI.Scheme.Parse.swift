//
//  RFC_3986.URI.Scheme.Parse.swift
//  swift-rfc-3986
//
//  URI scheme: ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
//

public import Parser_Primitives

extension RFC_3986.URI.Scheme {
    /// Parses a URI scheme per RFC 3986 Section 3.1.
    ///
    /// `scheme = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )`
    ///
    /// Returns the scheme as a byte slice (not lowercased — caller normalizes).
    public struct Parse<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension RFC_3986.URI.Scheme.Parse {
    public enum Error: Swift.Error, Sendable, Equatable {
        case expectedAlpha
    }
}

extension RFC_3986.URI.Scheme.Parse: Parser.`Protocol` {
    public typealias ParseOutput = Input
    public typealias Failure = RFC_3986.URI.Scheme.Parse<Input>.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Input {
        var index = input.startIndex

        // First character must be ALPHA
        guard index < input.endIndex else { throw .expectedAlpha }
        let first = input[index]
        guard (first >= 0x41 && first <= 0x5A) || (first >= 0x61 && first <= 0x7A) else {
            throw .expectedAlpha
        }
        input.formIndex(after: &index)

        // Remaining: ALPHA / DIGIT / "+" / "-" / "."
        while index < input.endIndex {
            let byte = input[index]
            guard Self._isSchemeChar(byte) else { break }
            input.formIndex(after: &index)
        }

        let result = input[input.startIndex..<index]
        input = input[index...]
        return result
    }

    @inlinable
    static func _isSchemeChar(_ byte: UInt8) -> Bool {
        switch byte {
        case 0x41...0x5A: true // A-Z
        case 0x61...0x7A: true // a-z
        case 0x30...0x39: true // 0-9
        case 0x2B: true        // +
        case 0x2D: true        // -
        case 0x2E: true        // .
        default: false
        }
    }
}
