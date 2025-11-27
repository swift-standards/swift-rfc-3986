public import INCITS_4_1986

// MARK: - URI Userinfo

extension RFC_3986.URI {
    /// URI userinfo component per RFC 3986 Section 3.2.1
    ///
    /// The userinfo subcomponent may consist of a user name and, optionally,
    /// scheme-specific information about how to gain authorization to access
    /// the resource.
    ///
    /// ## Security Note
    ///
    /// **The use of userinfo in URIs is deprecated** per RFC 3986 Section 3.2.1:
    /// - Passing authentication credentials in URIs is insecure
    /// - Applications should not render userinfo unless data is masked
    /// - Modern applications should use proper authentication mechanisms (OAuth, etc.)
    ///
    /// This type exists for RFC compliance and parsing legacy URIs only.
    ///
    /// ## Example
    /// ```swift
    /// // Simple username
    /// let username = try RFC_3986.URI.Userinfo("john")
    ///
    /// // Username with password (deprecated, insecure)
    /// let withPassword = try RFC_3986.URI.Userinfo("john:secret")
    ///
    /// // Access components
    /// print(withPassword.user)      // "john"
    /// print(withPassword.password)  // "secret"
    /// ```
    ///
    /// ## RFC 3986 Reference
    /// ```
    /// userinfo = *( unreserved / pct-encoded / sub-delims / ":" )
    /// unreserved = ALPHA / DIGIT / "-" / "." / "_" / "~"
    /// pct-encoded = "%" HEXDIG HEXDIG
    /// sub-delims = "!" / "$" / "&" / "'" / "(" / ")" / "*" / "+" / "," / ";" / "="
    /// ```
    public struct Userinfo: Sendable, Equatable, Hashable, Codable {
        /// RawValue type for RawRepresentable conformance
        public typealias RawValue = String

        /// The raw userinfo string (may contain username:password)
        public let rawValue: String

        /// Creates a userinfo component WITHOUT validation
        ///
        /// **Warning**: Bypasses RFC 3986 validation.
        /// Only use with compile-time constants or pre-validated values.
        ///
        /// - Parameters:
        ///   - unchecked: Void parameter to prevent accidental use
        ///   - rawValue: The raw userinfo value (unchecked)
        init(
            __unchecked _: Void,
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }
}

// MARK: - Serializable

extension RFC_3986.URI.Userinfo: UInt8.ASCII.Serializable {
    public static let serialize: @Sendable (Self) -> [UInt8] = [UInt8].init

    /// Parses userinfo from ASCII bytes (CANONICAL PRIMITIVE)
    ///
    /// This is the primitive parser that works at the byte level.
    /// RFC 3986 userinfo follows the pattern: *( unreserved / pct-encoded / sub-delims / ":" )
    ///
    /// ## Category Theory
    ///
    /// This is the fundamental parsing transformation:
    /// - **Domain**: [UInt8] (ASCII bytes)
    /// - **Codomain**: RFC_3986.URI.Userinfo (structured data)
    ///
    /// ## RFC 3986 Section 3.2.1
    ///
    /// ```
    /// userinfo = *( unreserved / pct-encoded / sub-delims / ":" )
    /// ```
    ///
    /// - Parameter bytes: The ASCII byte representation of the userinfo
    /// - Throws: `RFC_3986.URI.Userinfo.Error` if the bytes are malformed
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void) throws(Error)
    where Bytes.Element == UInt8 {
        // Validate userinfo characters at byte level
        var i = bytes.startIndex
        while i < bytes.endIndex {
            let byte = bytes[i]

            // Check for percent-encoding
            if byte == 0x25 {  // '%'
                // Validate percent-encoding: must have 2 hex digits following
                let next1 = bytes.index(after: i)
                guard next1 < bytes.endIndex else {
                    throw Error.invalidPercentEncoding(
                        String(decoding: bytes, as: UTF8.self),
                        reason: "'%' must be followed by 2 hex digits"
                    )
                }
                let next2 = bytes.index(after: next1)
                guard next2 < bytes.endIndex else {
                    throw Error.invalidPercentEncoding(
                        String(decoding: bytes, as: UTF8.self),
                        reason: "'%' must be followed by 2 hex digits"
                    )
                }

                guard bytes[next1].ascii.isHexDigit && bytes[next2].ascii.isHexDigit else {
                    throw Error.invalidPercentEncoding(
                        String(decoding: bytes, as: UTF8.self),
                        reason: "Invalid hex digits after '%'"
                    )
                }

                // Skip past the percent-encoded sequence
                i = bytes.index(after: next2)
                continue
            }

            // Check if valid userinfo character
            // unreserved: ALPHA / DIGIT / "-" / "." / "_" / "~"
            // sub-delims: "!" / "$" / "&" / "'" / "(" / ")" / "*" / "+" / "," / ";" / "="
            // plus ":"
            let isUnreserved = byte.ascii.isLetter || byte.ascii.isDigit
                || byte == 0x2D || byte == 0x2E || byte == 0x5F || byte == 0x7E  // - . _ ~
            let isSubDelim = byte == 0x21 || byte == 0x24 || byte == 0x26 || byte == 0x27  // ! $ & '
                || byte == 0x28 || byte == 0x29 || byte == 0x2A || byte == 0x2B  // ( ) * +
                || byte == 0x2C || byte == 0x3B || byte == 0x3D  // , ; =
            let isColon = byte == 0x3A  // :

            guard isUnreserved || isSubDelim || isColon else {
                throw Error.invalidCharacter(
                    String(decoding: bytes, as: UTF8.self),
                    byte: byte,
                    reason: "Only unreserved, sub-delims, ':', and percent-encoded allowed"
                )
            }

            i = bytes.index(after: i)
        }

        self.init(__unchecked: (), rawValue: String(decoding: bytes, as: UTF8.self))
    }
}

// MARK: - Byte Serialization

extension [UInt8] {
    /// Creates ASCII byte representation of an RFC 3986 URI userinfo
    ///
    /// This is the canonical serialization of userinfo to bytes.
    ///
    /// ## Category Theory
    ///
    /// This is the most universal serialization (natural transformation):
    /// - **Domain**: RFC_3986.URI.Userinfo (structured data)
    /// - **Codomain**: [UInt8] (ASCII bytes)
    ///
    /// - Parameter userinfo: The userinfo to serialize
    public init(_ userinfo: RFC_3986.URI.Userinfo) {
        self = Array(userinfo.rawValue.utf8)
    }
}

// MARK: - Protocol Conformances

extension RFC_3986.URI.Userinfo: UInt8.ASCII.RawRepresentable {}
extension RFC_3986.URI.Userinfo: CustomStringConvertible {}

// MARK: - Convenience Properties

extension RFC_3986.URI.Userinfo {
    /// The username portion (before the colon, if present)
    ///
    /// For "john:secret", returns "john"
    /// For "john", returns "john"
    public var user: String {
        if let colonIndex = rawValue.firstIndex(of: ":") {
            return String(rawValue[..<colonIndex])
        }
        return rawValue
    }

    /// The password portion (after the colon, if present)
    ///
    /// For "john:secret", returns "secret"
    /// For "john", returns nil
    ///
    /// - Warning: Passwords in URIs are insecure and deprecated by RFC 3986
    public var password: String? {
        guard let colonIndex = rawValue.firstIndex(of: ":") else {
            return nil
        }
        let afterColon = rawValue.index(after: colonIndex)
        return afterColon < rawValue.endIndex ? String(rawValue[afterColon...]) : nil
    }
}

// MARK: - Codable

extension RFC_3986.URI.Userinfo {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        try self.init(string)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
