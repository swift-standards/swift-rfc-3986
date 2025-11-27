public import INCITS_4_1986

// MARK: - URI Fragment

extension RFC_3986.URI {
    /// URI fragment component per RFC 3986 Section 3.5
    ///
    /// The fragment identifier component allows indirect identification of a secondary resource
    /// by reference to a primary resource and additional identifying information.
    ///
    /// Fragments are client-side only and are not sent to the server in HTTP requests.
    /// They are separated from the rest of the URI before dereferencing.
    ///
    /// ## Example
    /// ```swift
    /// // Create from string
    /// let fragment = try RFC_3986.URI.Fragment("section-1")
    /// print(fragment.value) // "section-1"
    ///
    /// // Use in URI
    /// let uri = try RFC_3986.URI("https://example.com/page#section-1")
    /// print(uri.fragment?.value) // "section-1"
    ///
    /// // Common patterns
    /// let heading = try RFC_3986.URI.Fragment("heading-intro")
    /// let anchor = try RFC_3986.URI.Fragment("top")
    /// ```
    ///
    /// ## RFC 3986 Reference
    /// ```
    /// fragment = *( pchar / "/" / "?" )
    /// ```
    ///
    /// Per RFC 3986 Section 3.5:
    /// > The fragment identifier component allows indirect identification of a
    /// > secondary resource by reference to a primary resource and additional
    /// > identifying information. [...] The semantics of a fragment identifier
    /// > are defined by the set of representations that might result from a
    /// > retrieval action on the primary resource.
    public struct Fragment: Sendable, Equatable, Hashable, Codable {
        /// RawValue type for RawRepresentable conformance
        public typealias RawValue = String

        /// The fragment value
        public let rawValue: String

        /// Creates a fragment WITHOUT validation
        ///
        /// **Warning**: Bypasses RFC 3986 validation.
        /// Only use with compile-time constants or pre-validated values.
        ///
        /// - Parameters:
        ///   - unchecked: Void parameter to prevent accidental use
        ///   - rawValue: The raw fragment value (unchecked)
        init(
            __unchecked _: Void,
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }
}

// MARK: - Serializable

extension RFC_3986.URI.Fragment: UInt8.ASCII.Serializable {
    public static let serialize: @Sendable (Self) -> [UInt8] = [UInt8].init

    /// Parses fragment from ASCII bytes (CANONICAL PRIMITIVE)
    ///
    /// This is the primitive parser that works at the byte level.
    /// RFC 3986 fragments follow the pattern: *( pchar / "/" / "?" )
    ///
    /// ## Category Theory
    ///
    /// This is the fundamental parsing transformation:
    /// - **Domain**: [UInt8] (ASCII bytes)
    /// - **Codomain**: RFC_3986.URI.Fragment (structured data)
    ///
    /// ## RFC 3986 Section 3.5
    ///
    /// ```
    /// fragment = *( pchar / "/" / "?" )
    /// ```
    ///
    /// - Parameter bytes: The ASCII byte representation of the fragment
    /// - Throws: `RFC_3986.URI.Fragment.Error` if the bytes are malformed
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void) throws(Error)
    where Bytes.Element == UInt8 {
        // Fragment can be empty per RFC 3986
        // Check for invalid characters
        for byte in bytes {
            // Fragments cannot contain '#' (0x23)
            if byte == 0x23 {
                throw Error.containsHash(String(decoding: bytes, as: UTF8.self))
            }

            // Check for newlines (LF: 0x0A, CR: 0x0D)
            if byte == 0x0A || byte == 0x0D {
                throw Error.containsNewline(String(decoding: bytes, as: UTF8.self))
            }
        }

        self.init(__unchecked: (), rawValue: String(decoding: bytes, as: UTF8.self))
    }
}

// MARK: - Byte Serialization

extension [UInt8] {
    /// Creates ASCII byte representation of an RFC 3986 URI fragment
    ///
    /// This is the canonical serialization of fragments to bytes.
    ///
    /// ## Category Theory
    ///
    /// This is the most universal serialization (natural transformation):
    /// - **Domain**: RFC_3986.URI.Fragment (structured data)
    /// - **Codomain**: [UInt8] (ASCII bytes)
    ///
    /// - Parameter fragment: The fragment to serialize
    public init(_ fragment: RFC_3986.URI.Fragment) {
        self = Array(fragment.rawValue.utf8)
    }
}

// MARK: - Protocol Conformances

extension RFC_3986.URI.Fragment: UInt8.ASCII.RawRepresentable {}
extension RFC_3986.URI.Fragment: CustomStringConvertible {}

// MARK: - Convenience Properties

extension RFC_3986.URI.Fragment {
    /// The fragment value (alias for rawValue for backward compatibility)
    public var value: String { rawValue }

    /// The string representation of the fragment
    ///
    /// Returns the fragment value (without leading "#").
    public var string: String {
        rawValue
    }

    /// Returns true if the fragment is empty
    public var isEmpty: Bool {
        rawValue.isEmpty
    }
}

// MARK: - Codable

extension RFC_3986.URI.Fragment {
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
