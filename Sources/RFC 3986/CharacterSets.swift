import Standards

extension RFC_3986 {
    /// Character sets defined in RFC 3986
    ///
    /// A type-safe wrapper around `Set<Character>` for RFC 3986 character sets.
    /// Use the static properties to access predefined character sets.
    ///
    /// Conforms to `SetAlgebra` so it behaves like `Set<Character>`:
    /// ```swift
    /// let chars = RFC_3986.CharacterSet.unreserved
    /// if chars.contains("a") { ... }
    /// let combined = chars.union(RFC_3986.CharacterSet.reserved)
    /// ```
    public struct CharacterSet: Sendable, SetAlgebra {
        /// The underlying character set
        internal var characters: Set<Character>

        /// Internal initializer for creating character sets from Set<Character>
        /// Use static properties for RFC 3986 defined character sets
        internal init(_ characters: Set<Character>) {
            self.characters = characters
        }

        // MARK: - SetAlgebra Conformance

        /// Creates an empty character set (required by SetAlgebra)
        public init() {
            self.characters = []
        }

        public func contains(_ member: Character) -> Bool {
            characters.contains(member)
        }

        public func union(_ other: Self) -> Self {
            Self(characters.union(other.characters))
        }

        public func intersection(_ other: Self) -> Self {
            Self(characters.intersection(other.characters))
        }

        public func symmetricDifference(_ other: Self) -> Self {
            Self(characters.symmetricDifference(other.characters))
        }

        @discardableResult
        public mutating func insert(_ newMember: Character) -> (inserted: Bool, memberAfterInsert: Character) {
            characters.insert(newMember)
        }

        @discardableResult
        public mutating func remove(_ member: Character) -> Character? {
            characters.remove(member)
        }

        @discardableResult
        public mutating func update(with newMember: Character) -> Character? {
            characters.update(with: newMember)
        }

        public mutating func formUnion(_ other: Self) {
            characters.formUnion(other.characters)
        }

        public mutating func formIntersection(_ other: Self) {
            characters.formIntersection(other.characters)
        }

        public mutating func formSymmetricDifference(_ other: Self) {
            characters.formSymmetricDifference(other.characters)
        }
    }
}

extension RFC_3986.CharacterSet {
    
    /// Unreserved characters per RFC 3986 Section 2.3
    ///
    /// Characters that can appear unencoded in URIs:
    /// `A-Z a-z 0-9 - . _ ~`
    ///
    /// URIs that differ only in the replacement of unreserved characters
    /// with their percent-encoded equivalents are considered equivalent.
    public static let unreserved: Self = .init(Set(
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
    ))
    
    /// Reserved characters per RFC 3986 Section 2.2
    ///
    /// Characters that serve as delimiters in URIs:
    /// `: / ? # [ ] @ ! $ & ' ( ) * + , ; =`
    ///
    /// These should be percent-encoded when representing data
    /// rather than serving as delimiters.
    public static let reserved: Self = .init(Set(
        ":/?#[]@!$&'()*+,;="
    ))
    
    /// General delimiters (subset of reserved) per RFC 3986 Section 2.2
    ///
    /// Characters: `: / ? # [ ] @`
    public static let genDelims: Self = .init(Set(
        ":/?#[]@"
    ))
    
    /// Sub-delimiters (subset of reserved) per RFC 3986 Section 2.2
    ///
    /// Characters: `! $ & ' ( ) * + , ; =`
    public static let subDelims: Self = .init(Set(
        "!$&'()*+,;="
    ))
    
    /// Characters allowed in a URI scheme per RFC 3986 Section 3.1
    ///
    /// Scheme names consist of a sequence of characters beginning with a letter
    /// and followed by any combination of letters, digits, plus (`+`), period (`.`),
    /// or hyphen (`-`).
    public static let scheme: Self = .init(Set(
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+.-"
    ))
    
    /// Characters allowed in userinfo per RFC 3986 Section 3.2.1
    ///
    /// Userinfo may consist of unreserved characters, percent-encoded octets,
    /// and sub-delimiters, plus the colon (`:`) character.
    public static let userinfo: Self = unreserved.union(subDelims).union(.init(Set([":"])))

    /// Characters allowed in host (reg-name) per RFC 3986 Section 3.2.2
    ///
    /// A registered name may consist of unreserved characters,
    /// percent-encoded octets, and sub-delimiters.
    public static let host: Self = unreserved.union(subDelims)

    /// Characters allowed in path segments per RFC 3986 Section 3.3
    ///
    /// Path characters include unreserved, sub-delimiters, and `:` and `@`.
    public static let pathSegment: Self = unreserved.union(subDelims).union(.init(Set([":", "@"])))

    /// Characters allowed in query per RFC 3986 Section 3.4
    ///
    /// Query characters include path segment characters plus `/` and `?`.
    public static let query: Self = pathSegment.union(.init(Set(["/", "?"])))

    /// Characters allowed in fragment per RFC 3986 Section 3.5
    ///
    /// Fragment characters are the same as query characters.
    public static let fragment: Self = query
}



// MARK: - RFC 3986 Percent Encoding Functions

extension RFC_3986 {
    /// Percent-encodes a string according to RFC 3986 Section 2.1
    ///
    /// Characters not in the allowed set are encoded as `%HH` where HH is
    /// the hexadecimal representation of the octet. Uppercase hexadecimal
    /// digits (A-F) are used per RFC 3986 normalization recommendations.
    ///
    /// - Parameters:
    ///   - string: The string to encode
    ///   - allowedCharacters: The set of characters that should not be encoded
    /// - Returns: The percent-encoded string with UPPERCASE hex
    public static func percentEncode(
        _ string: String,
        allowing allowedCharacters: RFC_3986.CharacterSet = .unreserved
    ) -> String {
        // Use generic implementation with UPPERCASE hex per RFC 3986
        String.percentEncoded(
            string: string,
            allowing: allowedCharacters.characters,
            uppercaseHex: true
        )
    }

    /// Decodes a percent-encoded string according to RFC 3986 Section 2.1
    ///
    /// Replaces percent-encoded octets (`%HH`) with their corresponding characters.
    /// Delegates to the generic String.percentDecoded from swift-standards.
    ///
    /// - Parameter string: The percent-encoded string to decode
    /// - Returns: The decoded string
    public static func percentDecode(_ string: String) -> String {
        String.percentDecoded(string: string)
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
                    if RFC_3986.CharacterSet.unreserved.contains(character) {
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

