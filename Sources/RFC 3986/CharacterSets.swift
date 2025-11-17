extension RFC_3986 {
    /// Character sets defined in RFC 3986
    public enum CharacterSets {
        /// Unreserved characters per RFC 3986 Section 2.3
        ///
        /// Characters that can appear unencoded in URIs:
        /// `A-Z a-z 0-9 - . _ ~`
        ///
        /// URIs that differ only in the replacement of unreserved characters
        /// with their percent-encoded equivalents are considered equivalent.
        public static let unreserved: Set<Character> = Set(
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
        )

        /// Reserved characters per RFC 3986 Section 2.2
        ///
        /// Characters that serve as delimiters in URIs:
        /// `: / ? # [ ] @ ! $ & ' ( ) * + , ; =`
        ///
        /// These should be percent-encoded when representing data
        /// rather than serving as delimiters.
        public static let reserved: Set<Character> = Set(
            ":/?#[]@!$&'()*+,;="
        )

        /// General delimiters (subset of reserved) per RFC 3986 Section 2.2
        ///
        /// Characters: `: / ? # [ ] @`
        public static let genDelims: Set<Character> = Set(
            ":/?#[]@"
        )

        /// Sub-delimiters (subset of reserved) per RFC 3986 Section 2.2
        ///
        /// Characters: `! $ & ' ( ) * + , ; =`
        public static let subDelims: Set<Character> = Set(
            "!$&'()*+,;="
        )

        /// Characters allowed in a URI scheme per RFC 3986 Section 3.1
        ///
        /// Scheme names consist of a sequence of characters beginning with a letter
        /// and followed by any combination of letters, digits, plus (`+`), period (`.`),
        /// or hyphen (`-`).
        public static let scheme: Set<Character> = Set(
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+.-"
        )

        /// Characters allowed in userinfo per RFC 3986 Section 3.2.1
        ///
        /// Userinfo may consist of unreserved characters, percent-encoded octets,
        /// and sub-delimiters, plus the colon (`:`) character.
        public static let userinfo: Set<Character> = unreserved.union(subDelims).union([":"])

        /// Characters allowed in host (reg-name) per RFC 3986 Section 3.2.2
        ///
        /// A registered name may consist of unreserved characters,
        /// percent-encoded octets, and sub-delimiters.
        public static let host: Set<Character> = unreserved.union(subDelims)

        /// Characters allowed in path segments per RFC 3986 Section 3.3
        ///
        /// Path characters include unreserved, sub-delimiters, and `:` and `@`.
        public static let pathSegment: Set<Character> = unreserved.union(subDelims).union([":", "@"])

        /// Characters allowed in query per RFC 3986 Section 3.4
        ///
        /// Query characters include path segment characters plus `/` and `?`.
        public static let query: Set<Character> = pathSegment.union(["/", "?"])

        /// Characters allowed in fragment per RFC 3986 Section 3.5
        ///
        /// Fragment characters are the same as query characters.
        public static let fragment: Set<Character> = query
    }

    // MARK: - Percent Encoding

    /// Percent-encodes a string according to RFC 3986 Section 2.1
    ///
    /// Characters not in the allowed set are encoded as `%HH` where HH is
    /// the hexadecimal representation of the octet. Uppercase hexadecimal
    /// digits (A-F) are used per RFC 3986 normalization recommendations.
    ///
    /// - Parameters:
    ///   - string: The string to encode
    ///   - allowedCharacters: The set of characters that should not be encoded
    /// - Returns: The percent-encoded string
    public static func percentEncode(
        _ string: String,
        allowing allowedCharacters: Set<Character> = CharacterSets.unreserved
    ) -> String {
        var result = ""
        for character in string {
            if allowedCharacters.contains(character) {
                result.append(character)
            } else {
                // Encode each UTF-8 byte
                for byte in String(character).utf8 {
                    result.append(String(format: "%%%02X", byte))
                }
            }
        }
        return result
    }

    /// Decodes a percent-encoded string according to RFC 3986 Section 2.1
    ///
    /// Replaces percent-encoded octets (`%HH`) with their corresponding characters.
    ///
    /// - Parameter string: The percent-encoded string to decode
    /// - Returns: The decoded string, or the original if decoding fails
    public static func percentDecode(_ string: String) -> String {
        var result = ""
        var index = string.startIndex

        while index < string.endIndex {
            if string[index] == "%" {
                // Try to read the next two hex digits
                let nextIndex = string.index(index, offsetBy: 1, limitedBy: string.endIndex)
                let thirdIndex = string.index(index, offsetBy: 3, limitedBy: string.endIndex)

                if let nextIndex = nextIndex,
                   let thirdIndex = thirdIndex,
                   thirdIndex <= string.endIndex {
                    let hexString = String(string[nextIndex..<thirdIndex])

                    if let byte = UInt8(hexString, radix: 16) {
                        // Collect bytes for multi-byte UTF-8 sequences
                        var bytes = [byte]
                        var currentIndex = thirdIndex

                        // Check if more bytes follow
                        while currentIndex < string.endIndex,
                              string[currentIndex] == "%",
                              let next = string.index(currentIndex, offsetBy: 1, limitedBy: string.endIndex),
                              let third = string.index(currentIndex, offsetBy: 3, limitedBy: string.endIndex),
                              third <= string.endIndex {
                            let nextHex = String(string[next..<third])
                            if let nextByte = UInt8(nextHex, radix: 16) {
                                bytes.append(nextByte)
                                currentIndex = third
                            } else {
                                break
                            }
                        }

                        // Try to decode UTF-8
                        if let decoded = String(bytes: bytes, encoding: .utf8) {
                            result.append(contentsOf: decoded)
                            index = currentIndex
                            continue
                        }
                    }
                }
            }

            result.append(string[index])
            index = string.index(after: index)
        }

        return result
    }

    /// Normalizes percent-encoding per RFC 3986 Section 6.2.2.2
    ///
    /// Uppercase hexadecimal digits in percent-encoded octets and
    /// decode any percent-encoded unreserved characters.
    ///
    /// - Parameter string: The string to normalize
    /// - Returns: The normalized string
    public static func normalizePercentEncoding(_ string: String) -> String {
        var result = ""
        var index = string.startIndex

        while index < string.endIndex {
            if string[index] == "%",
                let nextIndex = string.index(index, offsetBy: 1, limitedBy: string.endIndex),
                let thirdIndex = string.index(index, offsetBy: 3, limitedBy: string.endIndex)
            {
                let hexString = String(string[nextIndex..<thirdIndex])

                // Uppercase the hex digits
                let uppercasedHex = hexString.uppercased()

                // Check if this represents an unreserved character
                if let byte = UInt8(uppercasedHex, radix: 16) {
                    let scalar = Unicode.Scalar(byte)
                    let character = Character(scalar)

                    // If it's unreserved, decode it
                    if CharacterSets.unreserved.contains(character) {
                        result.append(character)
                    } else {
                        // Keep it encoded with uppercase hex
                        result.append("%")
                        result.append(uppercasedHex)
                    }
                } else {
                    // Invalid encoding, keep as-is
                    result.append(contentsOf: string[index..<thirdIndex])
                }

                index = thirdIndex
            } else {
                result.append(string[index])
                index = string.index(after: index)
            }
        }

        return result
    }
}

// MARK: - String Extensions for Convenience

extension String {
    /// Percent-encodes this string for use in URIs
    ///
    /// This is a convenience method that calls `RFC_3986.percentEncode(_:allowing:)`
    ///
    /// Example:
    /// ```swift
    /// let encoded = "hello world".percentEncoded()
    /// // "hello%20world"
    /// ```
    public func percentEncoded(
        allowing characterSet: Set<Character> = RFC_3986.CharacterSets.unreserved
    ) -> String {
        RFC_3986.percentEncode(self, allowing: characterSet)
    }

    /// Percent-decodes this string
    ///
    /// This is a convenience method that calls `RFC_3986.percentDecode(_:)`
    ///
    /// Example:
    /// ```swift
    /// let decoded = "hello%20world".percentDecoded()
    /// // "hello world"
    /// ```
    public func percentDecoded() -> String {
        RFC_3986.percentDecode(self)
    }

    /// Normalizes percent-encoding in this string
    ///
    /// This is a convenience method that calls `RFC_3986.normalizePercentEncoding(_:)`
    public func withNormalizedPercentEncoding() -> String {
        RFC_3986.normalizePercentEncoding(self)
    }

    /// Returns `true` if this string is a valid URI per RFC 3986
    public var isValidURI: Bool {
        RFC_3986.isValidURI(self)
    }

    /// Returns `true` if this string is a valid HTTP(S) URI
    public var isValidHTTPURI: Bool {
        RFC_3986.isValidHTTP(self)
    }

    /// Attempts to create a URI from this string
    ///
    /// Example:
    /// ```swift
    /// let uri = try "https://example.com".asURI()
    /// ```
    public func asURI() throws -> RFC_3986.URI {
        try RFC_3986.URI(self)
    }
}
