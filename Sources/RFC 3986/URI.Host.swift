
// MARK: - URI Host

extension RFC_3986.URI {
    /// URI host component per RFC 3986 Section 3.2.2
    ///
    /// The host subcomponent of authority is identified by an IP literal encapsulated
    /// within square brackets, an IPv4 address in dotted-decimal form, or a registered name.
    ///
    /// ## Example
    /// ```swift
    /// // IPv4 address
    /// let ipv4 = try RFC_3986.URI.Host("192.168.1.1")
    ///
    /// // IPv6 address (in brackets)
    /// let ipv6 = try RFC_3986.URI.Host("[2001:db8::1]")
    ///
    /// // Registered name (domain)
    /// let domain = try RFC_3986.URI.Host("example.com")
    /// ```
    ///
    /// ## RFC 3986 Reference
    /// ```
    /// host = IP-literal / IPv4address / reg-name
    /// IP-literal = "[" ( IPv6address / IPvFuture ) "]"
    /// ```
    public enum Host: Sendable, Equatable, Hashable {
        /// IPv4 address in dotted-decimal notation
        /// Example: "192.168.1.1"
        case ipv4(String)

        /// IPv6 address (stored without brackets)
        /// Example: "2001:db8::1"
        case ipv6(String)

        /// Registered name (DNS hostname or other name)
        /// Example: "example.com", "localhost"
        case registeredName(String)
    }
}

// MARK: - Initialization

extension RFC_3986.URI.Host {
    /// Creates a host from a string, automatically classifying the type
    ///
    /// - Parameter string: The host string to parse
    /// - Throws: `RFC_3986.Error.invalidComponent` if the host is invalid
    ///
    /// This initializer automatically detects whether the input is an IPv4 address,
    /// IPv6 address (in brackets), or a registered name.
    public init(_ string: String) throws {
        guard !string.isEmpty else {
            throw RFC_3986.Error.invalidComponent("Host cannot be empty")
        }

        // Check for IPv6 (enclosed in brackets)
        if string.hasPrefix("[") && string.hasSuffix("]") {
            let ipv6 = String(string.dropFirst().dropLast())
            guard Self.isValidIPv6(ipv6) else {
                throw RFC_3986.Error.invalidComponent(
                    "Invalid IPv6 address: \(ipv6)"
                )
            }
            self = .ipv6(ipv6)
            return
        }

        // Check for IPv4
        if Self.isValidIPv4(string) {
            self = .ipv4(string)
            return
        }

        // Otherwise treat as registered name
        // Validate registered name characters
        guard Self.isValidRegisteredName(string) else {
            throw RFC_3986.Error.invalidComponent(
                "Invalid registered name: \(string)"
            )
        }

        // Normalize to lowercase per RFC 3986 Section 6.2.2.1
        self = .registeredName(string.lowercased())
    }

    /// Creates a host without validation
    ///
    /// This is an internal optimization for static constants and validated values.
    ///
    /// - Parameter value: The host in the appropriate form (must be valid, not validated)
    /// - Warning: This skips validation. For public use, use `try!` with
    ///   the throwing initializer to make the risk explicit.
    internal static func unchecked(_ string: String) -> Self {
        if string.hasPrefix("[") && string.hasSuffix("]") {
            return .ipv6(String(string.dropFirst().dropLast()))
        } else if isValidIPv4(string) {
            return .ipv4(string)
        } else {
            return .registeredName(string.lowercased())
        }
    }
}

// MARK: - Convenience Properties

extension RFC_3986.URI.Host {
    /// The raw string representation of the host
    ///
    /// For IPv6, this includes the surrounding brackets.
    /// For IPv4 and registered names, returns the value as-is.
    public var rawValue: String {
        switch self {
        case .ipv4(let address):
            return address
        case .ipv6(let address):
            return "[\(address)]"
        case .registeredName(let name):
            return name
        }
    }

    /// Returns true if this is a loopback address
    public var isLoopback: Bool {
        switch self {
        case .ipv4(let addr):
            return addr.hasPrefix("127.")
        case .ipv6(let addr):
            return addr == "::1" || addr.lowercased() == "0:0:0:0:0:0:0:1"
        case .registeredName(let name):
            return name == "localhost"
        }
    }
}

// MARK: - Validation Helpers

extension RFC_3986.URI.Host {
    /// Validates if a string is a valid IPv4 address
    private static func isValidIPv4(_ string: String) -> Bool {
        let octets = string.split(separator: ".")
        guard octets.count == 4 else { return false }

        return octets.allSatisfy { octet in
            guard UInt8(octet) != nil else { return false }
            // Check for leading zeros (not allowed except for "0")
            if octet.count > 1 && octet.first == "0" {
                return false
            }
            return true
        }
    }

    /// Validates if a string is a valid IPv6 address (basic validation)
    ///
    /// This is a simplified validation. Full IPv6 validation is complex.
    private static func isValidIPv6(_ string: String) -> Bool {
        // Very basic IPv6 validation
        // Full validation would require much more complexity
        let validChars: Set<Character> = Set("0123456789abcdefABCDEF:")
        return string.allSatisfy { validChars.contains($0) }
            && string.contains(":")
    }

    /// Validates if a string is a valid registered name per RFC 3986
    ///
    /// reg-name = *( unreserved / pct-encoded / sub-delims )
    private static func isValidRegisteredName(_ string: String) -> Bool {
        // Allow unreserved chars, percent-encoded, and sub-delims
        let validChars = RFC_3986.CharacterSets.host.union(["%"])

        return string.allSatisfy { validChars.contains($0) }
    }
}

// MARK: - CustomStringConvertible

extension RFC_3986.URI.Host: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

// MARK: - Codable

extension RFC_3986.URI.Host: Codable {
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
