
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
    public struct Userinfo: Sendable, Equatable, Hashable {
        /// The raw userinfo string (may contain username:password)
        public let rawValue: String
    }
}

// MARK: - Initialization

extension RFC_3986.URI.Userinfo {
    /// Creates a userinfo component
    ///
    /// - Parameter rawValue: The userinfo string
    /// - Throws: `RFC_3986.Error` if the userinfo is invalid
    ///
    /// ## Example
    /// ```swift
    /// let userinfo = try RFC_3986.URI.Userinfo("user:password")
    /// ```
    public init(_ rawValue: String) throws {
        // Validate that userinfo contains only allowed characters
        // Per RFC 3986: unreserved / pct-encoded / sub-delims / ":"
        try Self.validate(rawValue)
        self.rawValue = rawValue
    }

    /// Creates a userinfo component without validation
    ///
    /// - Parameter rawValue: The userinfo string
    ///
    /// - Warning: This bypasses validation. Use the throwing init for untrusted input.
    public init(unchecked rawValue: String) {
        self.rawValue = rawValue
    }
}

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

// MARK: - Validation

extension RFC_3986.URI.Userinfo {
    /// Validates a userinfo string per RFC 3986
    ///
    /// Per RFC 3986 Section 3.2.1:
    /// ```
    /// userinfo = *( unreserved / pct-encoded / sub-delims / ":" )
    /// ```
    ///
    /// - Parameter string: The userinfo string to validate
    /// - Throws: `RFC_3986.Error` if the userinfo contains invalid characters
    private static func validate(_ string: String) throws {
        // Build allowed character set (userinfo characters plus % for percent-encoding)
        let allowedChars = RFC_3986.CharacterSet.userinfo.characters.union(["%"])

        // Check for any characters not in the allowed set
        if let invalidChar = string.first(where: { !allowedChars.contains($0) }) {
            throw RFC_3986.Error.invalidComponent(
                "Userinfo contains invalid character '\(invalidChar)'. Only unreserved, sub-delims, ':', and percent-encoded characters are allowed per RFC 3986 Section 3.2.1"
            )
        }

        // Validate percent-encoding if present
        if string.contains("%") {
            try validatePercentEncoding(string)
        }
    }

    /// Validates that percent-encoding is well-formed
    private static func validatePercentEncoding(_ string: String) throws {
        var index = string.startIndex
        while index < string.endIndex {
            if string[index] == "%" {
                // Must be followed by exactly 2 hex digits
                let nextIndex = string.index(after: index)
                guard nextIndex < string.endIndex else {
                    throw RFC_3986.Error.invalidComponent(
                        "Invalid percent-encoding: '%' must be followed by 2 hex digits"
                    )
                }

                let secondIndex = string.index(after: nextIndex)
                guard secondIndex < string.endIndex else {
                    throw RFC_3986.Error.invalidComponent(
                        "Invalid percent-encoding: '%' must be followed by 2 hex digits"
                    )
                }

                let hex1 = string[nextIndex]
                let hex2 = string[secondIndex]

                guard hex1.isHexDigit && hex2.isHexDigit else {
                    throw RFC_3986.Error.invalidComponent(
                        "Invalid percent-encoding: '%\(hex1)\(hex2)' - both characters must be hex digits"
                    )
                }

                index = string.index(after: secondIndex)
            } else {
                index = string.index(after: index)
            }
        }
    }
}

// MARK: - CustomStringConvertible

extension RFC_3986.URI.Userinfo: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

// MARK: - Codable

extension RFC_3986.URI.Userinfo: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        try self.init(string)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
