
// MARK: - URI Authority

extension RFC_3986.URI {
    /// URI authority component per RFC 3986 Section 3.2
    ///
    /// The authority component is preceded by a double slash ("//") and is terminated by
    /// the next slash ("/"), question mark ("?"), or number sign ("#") character, or by
    /// the end of the URI.
    ///
    /// ## Example
    /// ```swift
    /// // Authority with host only
    /// let simple = RFC_3986.URI.Authority(
    ///     host: try .init("example.com")
    /// )
    ///
    /// // Authority with host and port
    /// let withPort = RFC_3986.URI.Authority(
    ///     host: try .init("api.example.com"),
    ///     port: 8080
    /// )
    ///
    /// // Authority with userinfo, host, and port
    /// let full = RFC_3986.URI.Authority(
    ///     userinfo: "user:password",
    ///     host: try .init("ftp.example.com"),
    ///     port: 21
    /// )
    /// ```
    ///
    /// ## RFC 3986 Reference
    /// ```
    /// authority = [ userinfo "@" ] host [ ":" port ]
    /// userinfo = *( unreserved / pct-encoded / sub-delims / ":" )
    /// ```
    public struct Authority: Sendable, Equatable, Hashable {
        /// User information (username:password or similar)
        ///
        /// The use of userinfo in URIs is deprecated for security reasons.
        /// Per RFC 3986, applications should not render userinfo subcomponents
        /// unless the data is masked.
        public let userinfo: Userinfo?

        /// The host component (domain, IPv4, or IPv6)
        public let host: Host

        /// The port number
        public let port: Port?

        /// Creates an authority component
        ///
        /// - Parameters:
        ///   - userinfo: Optional user information
        ///   - host: The host component
        ///   - port: Optional port number
        public init(userinfo: Userinfo? = nil, host: Host, port: Port? = nil) {
            self.userinfo = userinfo
            self.host = host
            self.port = port
        }
    }
}

// MARK: - Initialization

extension RFC_3986.URI.Authority {
    /// Creates an authority from its string representation
    ///
    /// - Parameter string: The authority string (e.g., "user@example.com:8080")
    /// - Throws: `RFC_3986.Error` if the authority is invalid
    ///
    /// This parses an authority string in the form:
    /// `[userinfo@]host[:port]`
    public init(_ string: String) throws {
        var remaining = string

        // Extract userinfo if present (before @)
        let userinfo: RFC_3986.URI.Userinfo?
        if let atIndex = remaining.firstIndex(of: "@") {
            let userinfoString = String(remaining[..<atIndex])
            userinfo = try RFC_3986.URI.Userinfo(userinfoString)
            remaining = String(remaining[remaining.index(after: atIndex)...])
        } else {
            userinfo = nil
        }

        // Extract port if present (after last :, but not in IPv6 brackets)
        let port: RFC_3986.URI.Port?
        let host: RFC_3986.URI.Host

        // Check if this is an IPv6 address (starts with [)
        if remaining.hasPrefix("[") {
            // IPv6 - find the closing bracket
            guard let closeBracket = remaining.firstIndex(of: "]") else {
                throw RFC_3986.Error.invalidComponent("Unterminated IPv6 address")
            }

            let hostString = String(remaining[...closeBracket])
            remaining = String(remaining[remaining.index(after: closeBracket)...])

            // Check for port after ]
            if remaining.hasPrefix(":") {
                let portString = String(remaining.dropFirst())
                guard let portValue = RFC_3986.URI.Port(portString) else {
                    throw RFC_3986.Error.invalidComponent("Invalid port: \(portString)")
                }
                port = portValue
            } else if !remaining.isEmpty {
                throw RFC_3986.Error.invalidComponent("Invalid characters after IPv6: \(remaining)")
            } else {
                port = nil
            }

            host = try RFC_3986.URI.Host(hostString)
        } else {
            // IPv4 or registered name - port is after last :
            if let colonIndex = remaining.lastIndex(of: ":") {
                let hostString = String(remaining[..<colonIndex])
                let portString = String(remaining[remaining.index(after: colonIndex)...])

                guard let portValue = RFC_3986.URI.Port(portString) else {
                    throw RFC_3986.Error.invalidComponent("Invalid port: \(portString)")
                }

                host = try RFC_3986.URI.Host(hostString)
                port = portValue
            } else {
                host = try RFC_3986.URI.Host(remaining)
                port = nil
            }
        }

        self.init(userinfo: userinfo, host: host, port: port)
    }
}

// MARK: - Convenience Properties

extension RFC_3986.URI.Authority {
    /// The string representation of the authority
    ///
    /// Returns the authority in the form: `[userinfo@]host[:port]`
    public var rawValue: String {
        var result = ""

        if let userinfo = userinfo {
            result += "\(userinfo.rawValue)@"
        }

        result += host.rawValue

        if let port = port {
            result += ":\(port.value)"
        }

        return result
    }

    /// Returns true if this authority contains deprecated userinfo
    ///
    /// Per RFC 3986 Section 3.2.1, the use of userinfo in URIs is deprecated.
    public var hasUserinfo: Bool {
        userinfo != nil
    }
}

// MARK: - CustomStringConvertible

extension RFC_3986.URI.Authority: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

// MARK: - Codable

extension RFC_3986.URI.Authority: Codable {
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
