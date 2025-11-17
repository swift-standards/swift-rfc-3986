
// MARK: - URI Port

extension RFC_3986.URI {
    /// URI port component per RFC 3986 Section 3.2.3
    ///
    /// The port subcomponent of authority is designated by an optional decimal port number.
    ///
    /// ## Example
    /// ```swift
    /// let port = RFC_3986.URI.Port(8080)
    /// print(port.value) // 8080
    ///
    /// // Common ports
    /// let http = RFC_3986.URI.Port.http  // 80
    /// let https = RFC_3986.URI.Port.https  // 443
    /// ```
    ///
    /// ## RFC 3986 Reference
    /// ```
    /// port = *DIGIT
    /// ```
    public struct Port: Sendable, Equatable, Hashable {
        /// The port number (0-65535)
        public let value: UInt16
    }
}

// MARK: - Initialization

extension RFC_3986.URI.Port {
    /// Creates a port from a 16-bit unsigned integer
    ///
    /// - Parameter value: The port number (0-65535)
    public init(_ value: UInt16) {
        self.value = value
    }

    /// Creates a port from a string representation
    ///
    /// - Parameter string: The port as a string (e.g., "8080")
    /// - Returns: A Port if the string is a valid port number, nil otherwise
    public init?(_ string: String) {
        guard let port = UInt16(string) else { return nil }
        self.init(port)
    }
}

// MARK: - Common Ports

extension RFC_3986.URI.Port {
    /// HTTP default port (80)
    public static let http = Self(80)

    /// HTTPS default port (443)
    public static let https = Self(443)

    /// FTP default port (21)
    public static let ftp = Self(21)

    /// FTPS default port (990)
    public static let ftps = Self(990)

    /// SSH default port (22)
    public static let ssh = Self(22)

    /// Telnet default port (23)
    public static let telnet = Self(23)

    /// SMTP default port (25)
    public static let smtp = Self(25)

    /// DNS default port (53)
    public static let dns = Self(53)

    /// DHCP server default port (67)
    public static let dhcpServer = Self(67)

    /// DHCP client default port (68)
    public static let dhcpClient = Self(68)

    /// POP3 default port (110)
    public static let pop3 = Self(110)

    /// IMAP default port (143)
    public static let imap = Self(143)

    /// SNMP default port (161)
    public static let snmp = Self(161)

    /// LDAP default port (389)
    public static let ldap = Self(389)

    /// LDAPS default port (636)
    public static let ldaps = Self(636)

    /// MySQL default port (3306)
    public static let mysql = Self(3306)

    /// PostgreSQL default port (5432)
    public static let postgresql = Self(5432)

    /// Redis default port (6379)
    public static let redis = Self(6379)

    /// MongoDB default port (27017)
    public static let mongodb = Self(27017)
}

// MARK: - Convenience Properties

extension RFC_3986.URI.Port {
    /// Returns true if this is a well-known port (0-1023)
    public var isWellKnown: Bool {
        value < 1024
    }

    /// Returns true if this is a registered port (1024-49151)
    public var isRegistered: Bool {
        value >= 1024 && value < 49152
    }

    /// Returns true if this is a dynamic/private port (49152-65535)
    public var isDynamic: Bool {
        value >= 49152
    }
}

// MARK: - ExpressibleByIntegerLiteral

extension RFC_3986.URI.Port: ExpressibleByIntegerLiteral {
    /// Creates a port from an integer literal
    ///
    /// Example:
    /// ```swift
    /// let port: RFC_3986.URI.Port = 8080
    /// ```
    public init(integerLiteral value: UInt16) {
        self.init(value)
    }
}

// MARK: - CustomStringConvertible

extension RFC_3986.URI.Port: CustomStringConvertible {
    public var description: String {
        String(value)
    }
}

// MARK: - Codable

extension RFC_3986.URI.Port: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(UInt16.self)
        self.init(value)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

// MARK: - Comparable

extension RFC_3986.URI.Port: Comparable {
    public static func < (lhs: RFC_3986.URI.Port, rhs: RFC_3986.URI.Port) -> Bool {
        lhs.value < rhs.value
    }
}

// MARK: - RawRepresentable

extension RFC_3986.URI.Port: RawRepresentable {
    public var rawValue: UInt16 {
        value
    }

    public init?(rawValue: UInt16) {
        self.init(rawValue)
    }
}
