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
        public mutating func insert(
            _ newMember: Character
        ) -> (inserted: Bool, memberAfterInsert: Character) {
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
    public static let unreserved: Self = .init(
        Set(
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
        )
    )

    /// Reserved characters per RFC 3986 Section 2.2
    ///
    /// Characters that serve as delimiters in URIs:
    /// `: / ? # [ ] @ ! $ & ' ( ) * + , ; =`
    ///
    /// These should be percent-encoded when representing data
    /// rather than serving as delimiters.
    public static let reserved: Self = .init(
        Set(
            ":/?#[]@!$&'()*+,;="
        )
    )

    /// General delimiters (subset of reserved) per RFC 3986 Section 2.2
    ///
    /// Characters: `: / ? # [ ] @`
    public static let genDelims: Self = .init(
        Set(
            ":/?#[]@"
        )
    )

    /// Sub-delimiters (subset of reserved) per RFC 3986 Section 2.2
    ///
    /// Characters: `! $ & ' ( ) * + , ; =`
    public static let subDelims: Self = .init(
        Set(
            "!$&'()*+,;="
        )
    )

    /// Characters allowed in a URI scheme per RFC 3986 Section 3.1
    ///
    /// Scheme names consist of a sequence of characters beginning with a letter
    /// and followed by any combination of letters, digits, plus (`+`), period (`.`),
    /// or hyphen (`-`).
    public static let scheme: Self = .init(
        Set(
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+.-"
        )
    )

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

// MARK: - ByteSet for Efficient Byte-Level Operations

extension RFC_3986 {
    /// A set of ASCII bytes for efficient percent-encoding operations
    ///
    /// This is a byte-level equivalent of `CharacterSet` optimized for
    /// high-performance encoding/decoding operations on `[UInt8]` buffers.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let allowed = RFC_3986.ByteSet.unreserved
    /// if allowed.contains(0x41) { /* 'A' is unreserved */ }
    /// ```
    public struct ByteSet: Sendable {
        /// Bitmap for bytes 0-63
        @usableFromInline
        let low: UInt64
        /// Bitmap for bytes 64-127
        @usableFromInline
        let high: UInt64

        /// Creates a ByteSet from a bitmap pair
        @inlinable
        public init(low: UInt64, high: UInt64) {
            self.low = low
            self.high = high
        }

        /// Creates a ByteSet from a string of ASCII characters
        @inlinable
        public init(ascii characters: String) {
            var lo: UInt64 = 0
            var hi: UInt64 = 0
            for byte in characters.utf8 where byte < 128 {
                if byte < 64 {
                    lo |= 1 << UInt64(byte)
                } else {
                    hi |= 1 << UInt64(byte - 64)
                }
            }
            self.low = lo
            self.high = hi
        }

        /// Checks if the set contains the given byte
        @inlinable
        public func contains(_ byte: UInt8) -> Bool {
            guard byte < 128 else { return false }
            if byte < 64 {
                return (low & (1 << UInt64(byte))) != 0
            } else {
                return (high & (1 << UInt64(byte - 64))) != 0
            }
        }

        /// Returns the union of two ByteSets
        @inlinable
        public func union(_ other: ByteSet) -> ByteSet {
            ByteSet(low: low | other.low, high: high | other.high)
        }

        /// Returns the difference (self - other)
        @inlinable
        public func subtracting(_ other: ByteSet) -> ByteSet {
            ByteSet(low: low & ~other.low, high: high & ~other.high)
        }
    }
}

extension RFC_3986.ByteSet {
    /// Unreserved characters per RFC 3986 Section 2.3
    ///
    /// `A-Z a-z 0-9 - . _ ~`
    public static let unreserved = RFC_3986.ByteSet(
        ascii: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
    )

    /// Reserved characters per RFC 3986 Section 2.2
    ///
    /// `: / ? # [ ] @ ! $ & ' ( ) * + , ; =`
    public static let reserved = RFC_3986.ByteSet(
        ascii: ":/?#[]@!$&'()*+,;="
    )

    /// General delimiters per RFC 3986 Section 2.2
    ///
    /// `: / ? # [ ] @`
    public static let genDelims = RFC_3986.ByteSet(
        ascii: ":/?#[]@"
    )

    /// Sub-delimiters per RFC 3986 Section 2.2
    ///
    /// `! $ & ' ( ) * + , ; =`
    public static let subDelims = RFC_3986.ByteSet(
        ascii: "!$&'()*+,;="
    )

    /// Characters allowed in path segments per RFC 3986 Section 3.3
    ///
    /// unreserved + sub-delims + `:` + `@`
    public static let pathSegment = unreserved.union(subDelims).union(RFC_3986.ByteSet(ascii: ":@"))

    /// Characters allowed in query per RFC 3986 Section 3.4
    ///
    /// pathSegment + `/` + `?`
    public static let query = pathSegment.union(RFC_3986.ByteSet(ascii: "/?"))
}

// MARK: - Byte-Level Percent Encoding

extension RFC_3986 {
    /// Percent-encodes bytes according to RFC 3986 Section 2.1
    ///
    /// Bytes not in the allowed set are encoded as `%HH` where HH is
    /// the uppercase hexadecimal representation.
    ///
    /// - Parameters:
    ///   - bytes: The bytes to encode
    ///   - allowed: The set of bytes that should not be encoded
    /// - Returns: The percent-encoded bytes
    @inlinable
    public static func percentEncode<Bytes: Collection>(
        _ bytes: Bytes,
        allowing allowed: ByteSet = .unreserved
    ) -> [UInt8] where Bytes.Element == UInt8 {
        var result: [UInt8] = []
        result.reserveCapacity(bytes.count * 3)

        for byte in bytes {
            if allowed.contains(byte) {
                result.append(byte)
            } else {
                result.append(UInt8(ascii: "%"))
                result.append(hexDigit(byte >> 4))
                result.append(hexDigit(byte & 0x0F))
            }
        }
        return result
    }

    /// Percent-encodes bytes into a buffer according to RFC 3986 Section 2.1
    ///
    /// - Parameters:
    ///   - bytes: The bytes to encode
    ///   - buffer: The buffer to append encoded bytes to
    ///   - allowed: The set of bytes that should not be encoded
    @inlinable
    public static func percentEncode<Bytes: Collection, Buffer: RangeReplaceableCollection>(
        _ bytes: Bytes,
        into buffer: inout Buffer,
        allowing allowed: ByteSet = .unreserved
    ) where Bytes.Element == UInt8, Buffer.Element == UInt8 {
        for byte in bytes {
            if allowed.contains(byte) {
                buffer.append(byte)
            } else {
                buffer.append(UInt8(ascii: "%"))
                buffer.append(hexDigit(byte >> 4))
                buffer.append(hexDigit(byte & 0x0F))
            }
        }
    }

    /// Percent-decodes bytes according to RFC 3986 Section 2.1
    ///
    /// Replaces percent-encoded octets (`%HH`) with their byte values.
    ///
    /// - Parameter bytes: The percent-encoded bytes
    /// - Returns: The decoded bytes
    @inlinable
    public static func percentDecode<Bytes: Collection>(
        _ bytes: Bytes
    ) -> [UInt8] where Bytes.Element == UInt8 {
        var result: [UInt8] = []
        result.reserveCapacity(bytes.count)

        var iterator = bytes.makeIterator()
        while let byte = iterator.next() {
            if byte == UInt8(ascii: "%"),
                let hi = iterator.next(),
                let lo = iterator.next(),
                let hiVal = hexDigitValue(hi),
                let loVal = hexDigitValue(lo)
            {
                result.append((hiVal << 4) | loVal)
            } else {
                result.append(byte)
            }
        }
        return result
    }

    /// Converts a nibble (0-15) to an uppercase hex digit byte
    @inlinable
    static func hexDigit(_ nibble: UInt8) -> UInt8 {
        if nibble < 10 {
            return UInt8(ascii: "0") + nibble
        } else {
            return UInt8(ascii: "A") + nibble - 10
        }
    }

    /// Converts a hex digit byte to its value (0-15), or nil if invalid
    @inlinable
    static func hexDigitValue(_ byte: UInt8) -> UInt8? {
        switch byte {
        case UInt8(ascii: "0")...UInt8(ascii: "9"):
            return byte - UInt8(ascii: "0")
        case UInt8(ascii: "A")...UInt8(ascii: "F"):
            return byte - UInt8(ascii: "A") + 10
        case UInt8(ascii: "a")...UInt8(ascii: "f"):
            return byte - UInt8(ascii: "a") + 10
        default:
            return nil
        }
    }
}

// MARK: - RFC 3986 String Percent Encoding Functions

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
        var result = ""
        let hexDigits = Array("0123456789ABCDEF")

        for character in string {
            if allowedCharacters.contains(character) {
                result.append(character)
            } else {
                // Encode as UTF-8 bytes and percent-encode each byte
                for byte in String(character).utf8 {
                    result.append("%")
                    result.append(hexDigits[Int(byte >> 4)])
                    result.append(hexDigits[Int(byte & 0x0F)])
                }
            }
        }
        return result
    }

    /// Decodes a percent-encoded string according to RFC 3986 Section 2.1
    ///
    /// Replaces percent-encoded octets (`%HH`) with their corresponding characters.
    /// Properly handles multi-byte UTF-8 sequences.
    ///
    /// - Parameter string: The percent-encoded string to decode
    /// - Returns: The decoded string
    public static func percentDecode(_ string: String) -> String {
        var bytes: [UInt8] = []
        var index = string.startIndex

        while index < string.endIndex {
            if string[index] == "%",
                let nextIndex = string.index(index, offsetBy: 1, limitedBy: string.endIndex),
                let thirdIndex = string.index(index, offsetBy: 3, limitedBy: string.endIndex)
            {
                let hexString = String(string[nextIndex..<thirdIndex])
                if let byte = UInt8(hexString, radix: 16) {
                    bytes.append(byte)
                    index = thirdIndex
                    continue
                }
            }
            // Not a valid percent-encoded sequence, append the character's UTF-8 bytes
            for byte in String(string[index]).utf8 {
                bytes.append(byte)
            }
            index = string.index(after: index)
        }

        return String(decoding: bytes, as: UTF8.self)
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
