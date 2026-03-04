//
//  RFC_3986.URI.Query.Parse.swift
//  swift-rfc-3986
//
//  URI query: *( pchar / "/" / "?" )
//

public import Parser_Primitives

extension RFC_3986.URI.Query {
    /// Parses a URI query per RFC 3986 Section 3.4.
    ///
    /// `query = *( pchar / "/" / "?" )`
    ///
    /// Returns the raw byte slice (caller provides input after the `?` delimiter).
    /// Stops at `#` (fragment delimiter) or end of input.
    public struct Parse<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension RFC_3986.URI.Query.Parse: Parser.`Protocol` {
    public typealias ParseOutput = Input
    public typealias Failure = Never

    @inlinable
    public func parse(_ input: inout Input) -> Input {
        var index = input.startIndex
        while index < input.endIndex {
            let byte = input[index]
            // Stop at # (fragment delimiter)
            guard byte != 0x23 else { break }
            guard RFC_3986.Parse._isQueryOrFragmentChar(byte) else { break }
            input.formIndex(after: &index)
        }
        let result = input[input.startIndex..<index]
        input = input[index...]
        return result
    }
}
