//
//  RFC_3986.URI.Path.Parse.swift
//  swift-rfc-3986
//
//  URI path: *( pchar / "/" )
//

public import Parser_Primitives

extension RFC_3986.URI.Path {
    /// Parses a URI path per RFC 3986 Section 3.3.
    ///
    /// Consumes `pchar` and `/` characters. Returns the raw byte slice.
    /// Does not distinguish between path-abempty, path-absolute, path-rootless,
    /// or path-empty — that classification is left to the caller.
    public struct Parse<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension RFC_3986.URI.Path.Parse: Parser.`Protocol` {
    public typealias ParseOutput = Input
    public typealias Failure = Never

    @inlinable
    public func parse(_ input: inout Input) -> Input {
        var index = input.startIndex
        while index < input.endIndex {
            let byte = input[index]
            guard RFC_3986.Parse._isPchar(byte) || byte == 0x2F else { break }
            input.formIndex(after: &index)
        }
        let result = input[input.startIndex..<index]
        input = input[index...]
        return result
    }
}
