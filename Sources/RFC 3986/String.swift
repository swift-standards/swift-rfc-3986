// String.swift
// swift-rfc-3986
//
// RFC 3986 String extensions

// MARK: - String Extensions for RFC 3986 Convenience

extension String {
    /// Percent-encodes this string for use in URIs per RFC 3986
    ///
    /// Uses UPPERCASE hex encoding per RFC 3986 Section 6.2.2.2.
    /// Defaults to encoding all characters except unreserved characters.
    ///
    /// Example:
    /// ```swift
    /// let encoded = "hello world".percentEncoded()
    /// // "hello%20world"
    /// ```
    ///
    /// - Parameter allowing: Character set to preserve (defaults to RFC 3986 unreserved)
    /// - Returns: RFC 3986 compliant percent-encoded string
    public func percentEncoded(
        allowing characterSet: RFC_3986.CharacterSet = .unreserved
    ) -> String {
        RFC_3986.percentEncode(self, allowing: characterSet)
    }

    /// Parses this string as an RFC 3986 URI
    ///
    /// Returns `nil` if the string is not a valid URI.
    ///
    /// Example:
    /// ```swift
    /// "https://example.com".uri?.scheme.value  // "https"
    /// "https://example.com".uri?.host?.value   // "example.com"
    /// "invalid".uri                             // nil
    ///
    /// // Check validity
    /// if "https://example.com".uri != nil {
    ///     print("Valid URI")
    /// }
    /// ```
    public var uri: RFC_3986.URI? {
        try? RFC_3986.URI(self)
    }
}
