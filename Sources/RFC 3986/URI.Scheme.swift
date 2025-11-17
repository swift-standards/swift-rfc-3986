import Foundation

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
    public struct Scheme: Sendable, Equatable, Hashable {
        /// The scheme value (normalized to lowercase)
        public let value: String

        /// Creates a validated URI scheme
        ///
        /// - Parameter value: The scheme name to validate
        /// - Throws: `RFC_3986.Error.invalidComponent` if the scheme is invalid
        ///
        /// Per RFC 3986 Section 3.1, a scheme must:
        /// - Start with a letter (ALPHA)
        /// - Contain only letters, digits, +, -, or .
        public init(_ value: String) throws {
            // Validate non-empty
            guard !value.isEmpty else {
                throw RFC_3986.Error.invalidComponent("Scheme cannot be empty")
            }

            // Validate first character is a letter
            guard value.first?.isLetter == true else {
                throw RFC_3986.Error.invalidComponent(
                    "Scheme must start with a letter, got: \(value)"
                )
            }

            // Validate all characters are valid scheme characters
            let validChars = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "+-."))
            guard value.unicodeScalars.allSatisfy({ validChars.contains($0) }) else {
                throw RFC_3986.Error.invalidComponent(
                    "Scheme contains invalid characters. Only letters, digits, +, -, and . are allowed"
                )
            }

            // Normalize to lowercase per RFC 3986 Section 6.2.2.1
            self.value = value.lowercased()
        }

        /// Creates a scheme without validation
        ///
        /// This is an internal optimization for static constants and validated values.
        ///
        /// - Parameter value: The scheme name (must be valid, not validated)
        /// - Warning: This skips validation. For public use, use `try!` with
        ///   the throwing initializer to make the risk explicit.
        internal init(unchecked value: String) {
            self.value = value.lowercased()
        }

        // MARK: - Common Schemes

        /// HTTP scheme (http)
        public static let http = Scheme(unchecked: "http")

        /// HTTPS scheme (https)
        public static let https = Scheme(unchecked: "https")

        /// FTP scheme (ftp)
        public static let ftp = Scheme(unchecked: "ftp")

        /// FTPS scheme (ftps)
        public static let ftps = Scheme(unchecked: "ftps")

        /// File scheme (file)
        public static let file = Scheme(unchecked: "file")

        /// WebSocket scheme (ws)
        public static let ws = Scheme(unchecked: "ws")

        /// WebSocket Secure scheme (wss)
        public static let wss = Scheme(unchecked: "wss")

        /// Mailto scheme (mailto)
        public static let mailto = Scheme(unchecked: "mailto")

        /// Data scheme (data)
        public static let data = Scheme(unchecked: "data")

        // MARK: - Convenience Properties

        /// Returns true if this is a secure scheme (https, wss, ftps)
        public var isSecure: Bool {
            switch value {
            case "https", "wss", "ftps":
                return true
            default:
                return false
            }
        }

        /// Returns true if this is an HTTP-family scheme (http, https)
        public var isHTTP: Bool {
            value == "http" || value == "https"
        }

        /// Returns the default port for this scheme, if any
        public var defaultPort: UInt16? {
            switch value {
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
}

// MARK: - CustomStringConvertible

extension RFC_3986.URI.Scheme: CustomStringConvertible {
    public var description: String {
        value
    }
}

// MARK: - Codable

extension RFC_3986.URI.Scheme: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        try self.init(string)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

// MARK: - Comparable

extension RFC_3986.URI.Scheme: Comparable {
    public static func < (lhs: RFC_3986.URI.Scheme, rhs: RFC_3986.URI.Scheme) -> Bool {
        lhs.value < rhs.value
    }
}
