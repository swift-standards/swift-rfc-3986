//
//  RFC_3986.URI.Port.Parse.swift
//  swift-rfc-3986
//
//  URI port: *DIGIT → UInt16
//

public import Parser_Primitives

extension RFC_3986.URI.Port {
    /// Parses a URI port number per RFC 3986 Section 3.2.3.
    ///
    /// `port = *DIGIT`
    ///
    /// Requires at least one digit. Returns the port as a UInt16.
    public struct Parse<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension RFC_3986.URI.Port.Parse {
    public enum Error: Swift.Error, Sendable, Equatable {
        case expectedDigit
        case overflow
    }
}

extension RFC_3986.URI.Port.Parse: Parser.`Protocol` {
    public typealias ParseOutput = UInt16
    public typealias Failure = RFC_3986.URI.Port.Parse<Input>.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> UInt16 {
        var index = input.startIndex
        guard index < input.endIndex else { throw .expectedDigit }
        let first = input[index]
        guard first >= 0x30 && first <= 0x39 else { throw .expectedDigit }

        var value: UInt16 = UInt16(first &- 0x30)
        input.formIndex(after: &index)

        while index < input.endIndex {
            let byte = input[index]
            guard byte >= 0x30 && byte <= 0x39 else { break }
            let digit = UInt16(byte &- 0x30)
            let (v1, o1) = value.multipliedReportingOverflow(by: 10)
            let (v2, o2) = v1.addingReportingOverflow(digit)
            guard !o1 && !o2 else { throw .overflow }
            value = v2
            input.formIndex(after: &index)
        }

        input = input[index...]
        return value
    }
}
