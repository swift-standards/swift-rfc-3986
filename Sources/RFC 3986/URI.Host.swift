public import INCITS_4_1986

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

// MARK: - Serializable

extension RFC_3986.URI.Host: UInt8.ASCII.Serializable {
    public static let serialize: @Sendable (Self) -> [UInt8] = [UInt8].init

    /// Parses host from ASCII bytes (CANONICAL PRIMITIVE)
    ///
    /// This is the primitive parser that works at the byte level.
    /// RFC 3986 hosts can be: IP-literal / IPv4address / reg-name
    ///
    /// ## Category Theory
    ///
    /// This is the fundamental parsing transformation:
    /// - **Domain**: [UInt8] (ASCII bytes)
    /// - **Codomain**: RFC_3986.URI.Host (structured data)
    ///
    /// ## RFC 3986 Section 3.2.2
    ///
    /// ```
    /// host = IP-literal / IPv4address / reg-name
    /// IP-literal = "[" ( IPv6address / IPvFuture ) "]"
    /// ```
    ///
    /// - Parameter bytes: The ASCII byte representation of the host
    /// - Throws: `RFC_3986.URI.Host.Error` if the bytes are malformed
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void) throws(Error)
    where Bytes.Element == UInt8 {
        guard !bytes.isEmpty else {
            throw Error.empty
        }

        let string = String(decoding: bytes, as: UTF8.self)

        // Check for IPv6 (enclosed in brackets)
        if bytes.first == 0x5B {  // '['
            // Check that it ends with ']'
            let bytesArray = Array(bytes)
            guard bytesArray.last == 0x5D else {  // ']'
                throw Error.invalidIPv6(string, reason: "Missing closing bracket")
            }

            let ipv6Bytes = bytesArray.dropFirst().dropLast()
            let ipv6 = String(decoding: ipv6Bytes, as: UTF8.self)

            // Validate IPv6 characters (hex digits and colons)
            for byte in ipv6Bytes {
                guard byte.ascii.isHexDigit || byte == 0x3A else {  // ':'
                    throw Error.invalidIPv6(ipv6, reason: "Invalid character in IPv6 address")
                }
            }

            // Must contain at least one colon
            guard ipv6Bytes.contains(0x3A) else {
                throw Error.invalidIPv6(ipv6, reason: "IPv6 address must contain colons")
            }

            self = .ipv6(ipv6)
            return
        }

        // Check for IPv4 (4 dot-separated decimal octets)
        if Self.isValidIPv4Bytes(bytes) {
            self = .ipv4(string)
            return
        }

        // Otherwise treat as registered name
        // Validate registered name characters at byte level
        for byte in bytes {
            // unreserved: ALPHA / DIGIT / "-" / "." / "_" / "~"
            // sub-delims: "!" / "$" / "&" / "'" / "(" / ")" / "*" / "+" / "," / ";" / "="
            // plus percent-encoding "%"
            let isUnreserved = byte.ascii.isLetter || byte.ascii.isDigit
                || byte == 0x2D || byte == 0x2E || byte == 0x5F || byte == 0x7E  // - . _ ~
            let isSubDelim = byte == 0x21 || byte == 0x24 || byte == 0x26 || byte == 0x27  // ! $ & '
                || byte == 0x28 || byte == 0x29 || byte == 0x2A || byte == 0x2B  // ( ) * +
                || byte == 0x2C || byte == 0x3B || byte == 0x3D  // , ; =
            let isPercent = byte == 0x25  // %

            guard isUnreserved || isSubDelim || isPercent else {
                throw Error.invalidCharacter(
                    string,
                    byte: byte,
                    reason: "Only unreserved, sub-delims, and percent-encoded allowed in registered name"
                )
            }
        }

        // Normalize to lowercase per RFC 3986 Section 6.2.2.1
        self = .registeredName(string.lowercased())
    }

    /// Validates if bytes represent a valid IPv4 address
    private static func isValidIPv4Bytes<Bytes: Collection>(_ bytes: Bytes) -> Bool
    where Bytes.Element == UInt8 {
        var octetCount = 0
        var currentOctet: UInt16 = 0
        var digitCount = 0

        for byte in bytes {
            if byte == 0x2E {  // '.'
                guard digitCount > 0 && currentOctet <= 255 else { return false }
                // Check for leading zeros
                if digitCount > 1 && currentOctet < 10 { return false }
                if digitCount > 2 && currentOctet < 100 { return false }

                octetCount += 1
                currentOctet = 0
                digitCount = 0
            } else if byte.ascii.isDigit {
                let digit = UInt16(byte) - 0x30
                currentOctet = currentOctet * 10 + digit
                digitCount += 1
                if currentOctet > 255 || digitCount > 3 {
                    return false
                }
            } else {
                return false
            }
        }

        // Validate final octet
        guard digitCount > 0 && currentOctet <= 255 else { return false }
        if digitCount > 1 && currentOctet < 10 { return false }
        if digitCount > 2 && currentOctet < 100 { return false }

        octetCount += 1
        return octetCount == 4
    }
}

// MARK: - Byte Serialization

extension [UInt8] {
    /// Creates ASCII byte representation of an RFC 3986 URI host
    ///
    /// This is the canonical serialization of hosts to bytes.
    ///
    /// ## Category Theory
    ///
    /// This is the most universal serialization (natural transformation):
    /// - **Domain**: RFC_3986.URI.Host (structured data)
    /// - **Codomain**: [UInt8] (ASCII bytes)
    ///
    /// - Parameter host: The host to serialize
    public init(_ host: RFC_3986.URI.Host) {
        switch host {
        case .ipv4(let address):
            self = Array(address.utf8)
        case .ipv6(let address):
            // Wrap in brackets for serialization
            var bytes: [UInt8] = [0x5B]  // '['
            bytes.append(contentsOf: address.utf8)
            bytes.append(0x5D)  // ']'
            self = bytes
        case .registeredName(let name):
            self = Array(name.utf8)
        }
    }
}

// MARK: - CustomStringConvertible

extension RFC_3986.URI.Host: CustomStringConvertible {
    public var description: String {
        rawValue
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

// MARK: - Codable

extension RFC_3986.URI.Host: Codable {
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
