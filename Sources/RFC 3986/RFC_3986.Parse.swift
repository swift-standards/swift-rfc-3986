//
//  RFC_3986.Parse.swift
//  swift-rfc-3986
//
//  Namespace for URI parser combinators per RFC 3986 grammar.
//

import Parser_Primitives

extension RFC_3986 {
    public enum Parse {}
}

// MARK: - Character Classification Helpers

extension RFC_3986.Parse {
    /// unreserved = ALPHA / DIGIT / "-" / "." / "_" / "~"
    @inlinable
    public static func _isUnreserved(_ byte: UInt8) -> Bool {
        switch byte {
        case 0x41...0x5A, 0x61...0x7A, 0x30...0x39: true
        case 0x2D, 0x2E, 0x5F, 0x7E: true
        default: false
        }
    }

    /// sub-delims = "!" / "$" / "&" / "'" / "(" / ")" / "*" / "+" / "," / ";" / "="
    @inlinable
    public static func _isSubDelim(_ byte: UInt8) -> Bool {
        switch byte {
        case 0x21, 0x24, 0x26, 0x27, 0x28, 0x29: true
        case 0x2A, 0x2B, 0x2C, 0x3B, 0x3D: true
        default: false
        }
    }

    /// pchar = unreserved / pct-encoded / sub-delims / ":" / "@"
    @inlinable
    public static func _isPchar(_ byte: UInt8) -> Bool {
        _isUnreserved(byte) || _isSubDelim(byte)
            || byte == 0x3A || byte == 0x40 || byte == 0x25
    }

    /// userinfo char = unreserved / pct-encoded / sub-delims / ":"
    @inlinable
    public static func _isUserinfoChar(_ byte: UInt8) -> Bool {
        _isUnreserved(byte) || _isSubDelim(byte)
            || byte == 0x3A || byte == 0x25
    }

    /// reg-name char = unreserved / pct-encoded / sub-delims
    @inlinable
    public static func _isRegNameChar(_ byte: UInt8) -> Bool {
        _isUnreserved(byte) || _isSubDelim(byte) || byte == 0x25
    }

    /// query/fragment char = pchar / "/" / "?"
    @inlinable
    public static func _isQueryOrFragmentChar(_ byte: UInt8) -> Bool {
        _isPchar(byte) || byte == 0x2F || byte == 0x3F
    }
}
