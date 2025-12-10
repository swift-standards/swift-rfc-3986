public import INCITS_4_1986

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
        @available(*, deprecated, message: "deprecated for security reasons")
        public let userinfo: RFC_3986.URI.Userinfo?

        /// The host component (domain, IPv4, or IPv6)
        public let host: RFC_3986.URI.Host

        /// The port number
        public let port: RFC_3986.URI.Port?

        /// Creates an authority WITHOUT validation
        ///
        /// **Warning**: Bypasses RFC 3986 validation.
        /// Only use with compile-time constants or pre-validated values.
        ///
        /// - Parameters:
        ///   - unchecked: Void parameter to prevent accidental use
        ///   - userinfo: Optional user information
        ///   - host: The host component
        ///   - port: Optional port number
        init(
            __unchecked _: Void,
            userinfo: RFC_3986.URI.Userinfo?,
            host: RFC_3986.URI.Host,
            port: RFC_3986.URI.Port?
        ) {
            self.userinfo = userinfo
            self.host = host
            self.port = port
        }

        /// Creates an authority component
        ///
        /// - Parameters:
        ///   - userinfo: Optional user information
        ///   - host: The host component
        ///   - port: Optional port number
        public init(
            userinfo: RFC_3986.URI.Userinfo? = nil,
            host: RFC_3986.URI.Host,
            port: RFC_3986.URI.Port? = nil
        ) {
            self.init(__unchecked: (), userinfo: userinfo, host: host, port: port)
        }
    }
}

// MARK: - Serializable

extension RFC_3986.URI.Authority: Binary.ASCII.Serializable {
    public static func serialize<Buffer>(
        ascii authority: RFC_3986.URI.Authority,
        into buffer: inout Buffer
    ) where Buffer: RangeReplaceableCollection, Buffer.Element == UInt8 {
        if let userinfo = authority.userinfo {
            buffer.append(contentsOf: userinfo.rawValue.utf8)
            buffer.append(.ascii.commercialAt)  // @
        }

        buffer.append(contentsOf: [UInt8](authority.host))

        if let port = authority.port {
            buffer.append(.ascii.colon)  // :
            buffer.append(contentsOf: [UInt8](port))
        }
    }

    /// Parses authority from ASCII bytes (CANONICAL PRIMITIVE)
    ///
    /// This is the primitive parser that works at the byte level.
    /// RFC 3986 authority follows the pattern: [ userinfo "@" ] host [ ":" port ]
    ///
    /// ## Category Theory
    ///
    /// This is the fundamental parsing transformation:
    /// - **Domain**: [UInt8] (ASCII bytes)
    /// - **Codomain**: RFC_3986.URI.Authority (structured data)
    ///
    /// ## RFC 3986 Section 3.2
    ///
    /// ```
    /// authority = [ userinfo "@" ] host [ ":" port ]
    /// ```
    ///
    /// - Parameter bytes: The ASCII byte representation of the authority
    /// - Throws: `RFC_3986.URI.Authority.Error` if the bytes are malformed
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void) throws(Error)
    where Bytes.Element == UInt8 {
        let string = String(decoding: bytes, as: UTF8.self)
        var remaining = string

        // Extract userinfo if present (before @)
        let userinfo: RFC_3986.URI.Userinfo?
        if let atIndex = remaining.firstIndex(of: "@") {
            let userinfoString = String(remaining[..<atIndex])
            do {
                userinfo = try RFC_3986.URI.Userinfo(userinfoString)
            } catch {
                throw Error.invalidUserinfo(userinfoString, underlying: error)
            }
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
                throw Error.unterminatedIPv6(string)
            }

            let hostString = String(remaining[...closeBracket])
            remaining = String(remaining[remaining.index(after: closeBracket)...])

            // Check for port after ]
            if remaining.hasPrefix(":") {
                let portString = String(remaining.dropFirst())
                guard let portValue = RFC_3986.URI.Port(portString) else {
                    throw Error.invalidPort(portString)
                }
                port = portValue
            } else if !remaining.isEmpty {
                throw Error.invalidCharactersAfterIPv6(remaining)
            } else {
                port = nil
            }

            do {
                host = try RFC_3986.URI.Host(hostString)
            } catch {
                throw Error.invalidHost(hostString, underlying: error)
            }
        } else {
            // IPv4 or registered name - port is after last :
            if let colonIndex = remaining.lastIndex(of: ":") {
                let hostString = String(remaining[..<colonIndex])
                let portString = String(remaining[remaining.index(after: colonIndex)...])

                guard let portValue = RFC_3986.URI.Port(portString) else {
                    throw Error.invalidPort(portString)
                }

                do {
                    host = try RFC_3986.URI.Host(hostString)
                } catch {
                    throw Error.invalidHost(hostString, underlying: error)
                }
                port = portValue
            } else {
                do {
                    host = try RFC_3986.URI.Host(remaining)
                } catch {
                    throw Error.invalidHost(remaining, underlying: error)
                }
                port = nil
            }
        }

        self.init(__unchecked: (), userinfo: userinfo, host: host, port: port)
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
    public init(_ string: some StringProtocol) throws {
        var remaining = String(string)

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
}

// MARK: - CustomStringConvertible

extension RFC_3986.URI.Authority: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

// MARK: - Codable

extension RFC_3986.URI.Authority: Codable {
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

// MARK: - Error

extension RFC_3986.URI.Authority {
    /// Errors that can occur when parsing an authority component
    public enum Error: Swift.Error, Sendable, Equatable, CustomStringConvertible {
        /// The userinfo component is invalid
        case invalidUserinfo(String, underlying: any Swift.Error)

        /// The host component is invalid
        case invalidHost(String, underlying: any Swift.Error)

        /// The port component is invalid
        case invalidPort(String)

        /// IPv6 address is not terminated with ]
        case unterminatedIPv6(String)

        /// Invalid characters after IPv6 address
        case invalidCharactersAfterIPv6(String)

        public var description: String {
            switch self {
            case .invalidUserinfo(let value, _):
                return "Invalid userinfo: '\(value)'"
            case .invalidHost(let value, _):
                return "Invalid host: '\(value)'"
            case .invalidPort(let value):
                return "Invalid port: '\(value)'"
            case .unterminatedIPv6(let value):
                return "Unterminated IPv6 address in: '\(value)'"
            case .invalidCharactersAfterIPv6(let value):
                return "Invalid characters after IPv6 address: '\(value)'"
            }
        }

        public static func == (lhs: Error, rhs: Error) -> Bool {
            switch (lhs, rhs) {
            case (.invalidUserinfo(let l, _), .invalidUserinfo(let r, _)): l == r
            case (.invalidHost(let l, _), .invalidHost(let r, _)): l == r
            case (.invalidPort(let l), .invalidPort(let r)): l == r
            case (.unterminatedIPv6(let l), .unterminatedIPv6(let r)): l == r
            case (.invalidCharactersAfterIPv6(let l), .invalidCharactersAfterIPv6(let r)): l == r
            default: false
            }
        }
    }
}
