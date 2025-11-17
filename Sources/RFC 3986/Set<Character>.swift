// Set<Character>.swift
// swift-rfc-3986
//
// Convenience extensions for RFC 3986 character sets

extension Set where Element == Character {
    /// Unreserved characters per RFC 3986 Section 2.3
    ///
    /// Characters that can appear unencoded in URIs: `A-Z a-z 0-9 - . _ ~`
    public static var uriUnreserved: Self {
        RFC_3986.CharacterSets.unreserved
    }

    /// Reserved characters per RFC 3986 Section 2.2
    ///
    /// Characters that serve as delimiters in URIs: `: / ? # [ ] @ ! $ & ' ( ) * + , ; =`
    public static var uriReserved: Self {
        RFC_3986.CharacterSets.reserved
    }

    /// General delimiters (subset of reserved) per RFC 3986 Section 2.2
    ///
    /// Characters: `: / ? # [ ] @`
    public static var uriGeneralDelimiters: Self {
        RFC_3986.CharacterSets.genDelims
    }

    /// Sub-delimiters (subset of reserved) per RFC 3986 Section 2.2
    ///
    /// Characters: `! $ & ' ( ) * + , ; =`
    public static var uriSubDelimiters: Self {
        RFC_3986.CharacterSets.subDelims
    }

    /// Characters allowed in a URI scheme per RFC 3986 Section 3.1
    ///
    /// Scheme names consist of letters, digits, plus (`+`), period (`.`), or hyphen (`-`)
    public static var uriSchemeAllowed: Self {
        RFC_3986.CharacterSets.scheme
    }

    /// Characters allowed in userinfo per RFC 3986 Section 3.2.1
    ///
    /// Userinfo may consist of unreserved characters, percent-encoded octets,
    /// and sub-delimiters, plus the colon (`:`) character
    public static var uriUserInfoAllowed: Self {
        RFC_3986.CharacterSets.userinfo
    }

    /// Characters allowed in host (reg-name) per RFC 3986 Section 3.2.2
    ///
    /// A registered name may consist of unreserved characters,
    /// percent-encoded octets, and sub-delimiters
    public static var uriHostAllowed: Self {
        RFC_3986.CharacterSets.host
    }

    /// Characters allowed in path segments per RFC 3986 Section 3.3
    ///
    /// Path characters include unreserved, sub-delimiters, and `:` and `@`
    public static var uriPathSegmentAllowed: Self {
        RFC_3986.CharacterSets.pathSegment
    }

    /// Characters allowed in query per RFC 3986 Section 3.4
    ///
    /// Query characters include path segment characters plus `/` and `?`
    public static var uriQueryAllowed: Self {
        RFC_3986.CharacterSets.query
    }

    /// Characters allowed in fragment per RFC 3986 Section 3.5
    ///
    /// Fragment characters are the same as query characters
    public static var uriFragmentAllowed: Self {
        RFC_3986.CharacterSets.fragment
    }
}
