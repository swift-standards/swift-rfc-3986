public import INCITS_4_1986

// MARK: - URI Scheme

extension RFC_3986.URI {
    /// URI scheme component per RFC 3986 Section 3.1
    ///
    /// Schemes consist of a sequence of characters beginning with a letter and followed
    /// by any combination of letters, digits, plus (+), period (.), or hyphen (-).
    ///
    /// Scheme names are case-insensitive and normalized to lowercase per RFC 3986.
    ///
    /// ## Example
    /// ```swift
    /// let scheme = try RFC_3986.URI.Scheme("https")
    /// print(scheme.value) // "https"
    ///
    /// // Case normalization
    /// let normalized = try RFC_3986.URI.Scheme("HTTPS")
    /// print(normalized.value) // "https"
    ///
    /// // Invalid scheme
    /// try RFC_3986.URI.Scheme("123invalid") // throws error
    /// ```
    ///
    /// ## RFC 3986 Reference
    /// ```
    /// scheme = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
    /// ```
    public struct Scheme: Sendable, Equatable, Hashable, Codable {
        /// RawValue type for RawRepresentable conformance
        public typealias RawValue = String

        /// The scheme value (normalized to lowercase)
        public let rawValue: String

        /// Creates a scheme WITHOUT validation
        ///
        /// **Warning**: Bypasses RFC 3986 validation.
        /// Only use with compile-time constants or pre-validated values.
        ///
        /// - Parameters:
        ///   - unchecked: Void parameter to prevent accidental use
        ///   - rawValue: The raw scheme value (unchecked)
        init(
            __unchecked _: Void,
            rawValue: String
        ) {
            self.rawValue = rawValue.lowercased()
        }
    }
}

// MARK: - Serializable

extension RFC_3986.URI.Scheme: UInt8.ASCII.Serializable {
    public static let serialize: @Sendable (Self) -> [UInt8] = [UInt8].init

    /// Parses scheme from ASCII bytes (CANONICAL PRIMITIVE)
    ///
    /// This is the primitive parser that works at the byte level.
    /// RFC 3986 schemes are ASCII-only.
    ///
    /// ## Category Theory
    ///
    /// This is the fundamental parsing transformation:
    /// - **Domain**: [UInt8] (ASCII bytes)
    /// - **Codomain**: RFC_3986.URI.Scheme (structured data)
    ///
    /// String-based parsing is derived as composition:
    /// ```
    /// String → [UInt8] (UTF-8 bytes) → Scheme
    /// ```
    ///
    /// ## RFC 3986 Section 3.1
    ///
    /// ```
    /// scheme = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
    /// ```
    ///
    /// - Parameter bytes: The ASCII byte representation of the scheme
    /// - Throws: `RFC_3986.URI.Scheme.Error` if the bytes are malformed
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void) throws(Error)
    where Bytes.Element == UInt8 {
        guard let firstByte = bytes.first else {
            throw Error.empty
        }

        guard firstByte.ascii.isLetter else {
            throw Error.invalidStart(String(decoding: bytes, as: UTF8.self), byte: firstByte)
        }

        for byte in bytes.dropFirst() {
            let valid = byte.ascii.isLetter
                || byte.ascii.isDigit
                || byte == .ascii.plusSign
                || byte == .ascii.hyphen
                || byte == .ascii.period
            guard valid else {
                throw Error.invalidCharacter(
                    String(decoding: bytes, as: UTF8.self),
                    byte: byte,
                    reason: "Only letters, digits, +, -, . allowed"
                )
            }
        }

        // Normalize to lowercase per RFC 3986 Section 6.2.2.1
        self.init(__unchecked: (), rawValue: String(decoding: bytes, as: UTF8.self))
    }
}

// MARK: - Byte Serialization

extension [UInt8] {
    /// Creates ASCII byte representation of an RFC 3986 URI scheme
    ///
    /// This is the canonical serialization of schemes to bytes.
    /// RFC 3986 schemes are ASCII-only by definition.
    ///
    /// ## Category Theory
    ///
    /// This is the most universal serialization (natural transformation):
    /// - **Domain**: RFC_3986.URI.Scheme (structured data)
    /// - **Codomain**: [UInt8] (ASCII bytes)
    ///
    /// String representation is derived as composition:
    /// ```
    /// Scheme → [UInt8] (ASCII) → String (UTF-8 interpretation)
    /// ```
    ///
    /// - Parameter scheme: The scheme to serialize
    public init(_ scheme: RFC_3986.URI.Scheme) {
        self = Array(scheme.rawValue.utf8)
    }
}

// MARK: - Protocol Conformances

extension RFC_3986.URI.Scheme: UInt8.ASCII.RawRepresentable {}
extension RFC_3986.URI.Scheme: CustomStringConvertible {}


// MARK: - Common Schemes

extension RFC_3986.URI.Scheme {
    /// HTTP scheme (http)
    public static let http = Self(__unchecked: (), rawValue: "http")

    /// HTTPS scheme (https)
    public static let https = Self(__unchecked: (), rawValue: "https")

    /// FTP scheme (ftp)
    public static let ftp = Self(__unchecked: (), rawValue: "ftp")

    /// FTPS scheme (ftps)
    public static let ftps = Self(__unchecked: (), rawValue: "ftps")

    /// File scheme (file)
    public static let file = Self(__unchecked: (), rawValue: "file")

    /// WebSocket scheme (ws)
    public static let ws = Self(__unchecked: (), rawValue: "ws")

    /// WebSocket Secure scheme (wss)
    public static let wss = Self(__unchecked: (), rawValue: "wss")

    /// Mailto scheme (mailto)
    public static let mailto = Self(__unchecked: (), rawValue: "mailto")

    /// Data scheme (data)
    public static let data = Self(__unchecked: (), rawValue: "data")
}

// MARK: - Convenience Properties

extension RFC_3986.URI.Scheme {
    /// The scheme value (alias for rawValue for backward compatibility)
    public var value: String { rawValue }

    /// Returns true if this is a secure scheme (https, wss, ftps)
    public var isSecure: Bool {
        switch rawValue {
        case "https", "wss", "ftps":
            return true
        default:
            return false
        }
    }

    /// Returns true if this is an HTTP-family scheme (http, https)
    public var isHTTP: Bool {
        rawValue == "http" || rawValue == "https"
    }

    /// Returns the default port for this scheme, if any
    public var defaultPort: UInt16? {
        switch rawValue {
        case "http": return 80
        case "https": return 443
        case "ftp": return 21
        case "ftps": return 990
        case "ws": return 80
        case "wss": return 443
        default: return nil
        }
    }
}

// MARK: - Codable

extension RFC_3986.URI.Scheme {
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

// MARK: - Comparable

extension RFC_3986.URI.Scheme: Comparable {
    public static func < (lhs: RFC_3986.URI.Scheme, rhs: RFC_3986.URI.Scheme) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
