//
//  RFC_3986.URI.Host.Parse.swift
//  swift-rfc-3986
//
//  URI host: IP-literal / IPv4address / reg-name
//

public import Parser_Primitives

extension RFC_3986.URI.Host {
    /// Parses a URI host per RFC 3986 Section 3.2.2.
    ///
    /// `host = IP-literal / IPv4address / reg-name`
    ///
    /// Returns the raw byte slice including brackets for IP-literals.
    /// Does not distinguish between IPv4 and reg-name (both consume the same
    /// character set at the byte level).
    public struct Parse<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension RFC_3986.URI.Host.Parse {
    public enum Error: Swift.Error, Sendable, Equatable {
        case unterminatedIPLiteral
    }
}

extension RFC_3986.URI.Host.Parse: Parser.`Protocol` {
    public typealias ParseOutput = Input
    public typealias Failure = RFC_3986.URI.Host.Parse<Input>.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Input {
        guard input.startIndex < input.endIndex else {
            return input[input.startIndex..<input.startIndex]
        }

        if input[input.startIndex] == 0x5B {
            // IP-literal: "[" ( IPv6address / IPvFuture ) "]"
            var index = input.startIndex
            input.formIndex(after: &index)
            while index < input.endIndex {
                if input[index] == 0x5D {
                    input.formIndex(after: &index)
                    let result = input[input.startIndex..<index]
                    input = input[index...]
                    return result
                }
                input.formIndex(after: &index)
            }
            throw .unterminatedIPLiteral
        } else {
            // reg-name / IPv4address: *( unreserved / pct-encoded / sub-delims )
            var index = input.startIndex
            while index < input.endIndex {
                let byte = input[index]
                guard RFC_3986.Parse._isRegNameChar(byte) else { break }
                input.formIndex(after: &index)
            }
            let result = input[input.startIndex..<index]
            input = input[index...]
            return result
        }
    }
}
