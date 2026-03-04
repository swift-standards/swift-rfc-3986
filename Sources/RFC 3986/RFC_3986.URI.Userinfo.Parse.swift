//
//  RFC_3986.URI.Userinfo.Parse.swift
//  swift-rfc-3986
//
//  URI userinfo: *( unreserved / pct-encoded / sub-delims / ":" )
//

public import Parser_Primitives

extension RFC_3986.URI.Userinfo {
    /// Parses URI userinfo per RFC 3986 Section 3.2.1.
    ///
    /// `userinfo = *( unreserved / pct-encoded / sub-delims / ":" )`
    ///
    /// Returns the raw byte slice. Does not consume the trailing `@`.
    public struct Parse<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension RFC_3986.URI.Userinfo.Parse: Parser.`Protocol` {
    public typealias ParseOutput = Input
    public typealias Failure = Never

    @inlinable
    public func parse(_ input: inout Input) -> Input {
        var index = input.startIndex
        while index < input.endIndex {
            let byte = input[index]
            guard RFC_3986.Parse._isUserinfoChar(byte) else { break }
            input.formIndex(after: &index)
        }
        let result = input[input.startIndex..<index]
        input = input[index...]
        return result
    }
}
