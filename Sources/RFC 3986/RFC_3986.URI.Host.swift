public import INCITS_4_1986
public import IPv4_Standard
public import IPv6_Standard

// MARK: - URI Host

extension RFC_3986.URI {
    /// URI host component per RFC 3986 Section 3.2.2
    ///
    /// The host subcomponent of authority is identified by an IP literal encapsulated
    /// within square brackets, an IPv4 address in dotted-decimal form, or a registered name.
    ///
    /// ## Type Safety
    ///
    /// This implementation uses strongly-typed addresses:
    /// - **IPv4**: `RFC_791.IPv4.Address` for validated dotted-decimal addresses
    /// - **IPv6**: `RFC_4007.IPv6.ScopedAddress` for addresses with optional zone identifiers
    /// - **Registered Name**: `String` for DNS hostnames and other names
    ///
    /// ## Example
    /// ```swift
    /// // IPv4 address
    /// let ipv4 = try RFC_3986.URI.Host("192.168.1.1")
    ///
    /// // IPv6 address (in brackets)
    /// let ipv6 = try RFC_3986.URI.Host("[2001:db8::1]")
    ///
    /// // IPv6 with zone identifier
    /// let scoped = try RFC_3986.URI.Host("[fe80::1%eth0]")
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
        ///
        /// Uses `RFC_791.IPv4.Address` for type-safe, validated addresses.
        ///
        /// Example: "192.168.1.1"
        case ipv4(RFC_791.IPv4.Address)

        /// IPv6 address with optional zone identifier
        ///
        /// Uses `RFC_4007.IPv6.ScopedAddress` to support both plain addresses
        /// and scoped addresses with zone identifiers (e.g., `fe80::1%eth0`).
        ///
        /// The zone identifier is serialized within the brackets per RFC 6874:
        /// `[fe80::1%25eth0]` (percent-encoded for URIs)
        ///
        /// Example: "2001:db8::1", "fe80::1%eth0"
        case ipv6(RFC_4007.IPv6.ScopedAddress)

        /// Registered name (DNS hostname or other name)
        ///
        /// Normalized to lowercase per RFC 3986 Section 6.2.2.1.
        ///
        /// Example: "example.com", "localhost"
        case registeredName(String)
    }
}

// MARK: - Serializable

extension RFC_3986.URI.Host: Binary.ASCII.Serializable {
    public static func serialize<Buffer>(
        ascii host: RFC_3986.URI.Host,
        into buffer: inout Buffer
    ) where Buffer: RangeReplaceableCollection, Buffer.Element == UInt8 {
        switch host {
        case .ipv4(let address):
            buffer.append(ascii: address)

        case .ipv6(let scopedAddress):
            buffer.append(.ascii.leftBracket)
            buffer.append(ascii: scopedAddress.address)

            if let zone = scopedAddress.zone {
                buffer.append(.ascii.percentSign)
                buffer.append(.ascii.2)
                buffer.append(.ascii.5)
                buffer.append(contentsOf: zone.utf8)
            }

            buffer.append(.ascii.rightBracket)

        case .registeredName(let name):
            buffer.append(utf8: name)
        }
    }

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

        // Check for IP-literal (enclosed in brackets)
        if bytes.first == 0x5B {  // '['
            // Check that it ends with ']'
            let bytesArray = Array(bytes)
            guard bytesArray.last == 0x5D else {  // ']'
                throw Error.invalidIPv6(string, reason: "Missing closing bracket")
            }

            // Extract content between brackets
            let innerBytes = bytesArray.dropFirst().dropLast()

            // Check for zone identifier (% encoded as %25 in URIs per RFC 6874)
            // In URI format: [fe80::1%25eth0]
            // We need to decode %25 back to % for the scoped address parser
            let innerArray = Array(innerBytes)
            var decodedBytes: [UInt8] = []
            decodedBytes.reserveCapacity(innerArray.count)

            var i = 0
            while i < innerArray.count {
                if innerArray[i] == 0x25 {  // '%'
                    // Check for %25 (percent-encoded percent)
                    if i + 2 < innerArray.count
                        && innerArray[i + 1] == 0x32  // '2'
                        && innerArray[i + 2] == 0x35  // '5'
                    {
                        // Decode %25 to %
                        decodedBytes.append(0x25)
                        i += 3
                        continue
                    }
                }
                decodedBytes.append(innerArray[i])
                i += 1
            }

            // Try to parse as IPv6 scoped address
            do {
                let scopedAddress = try RFC_4007.IPv6.ScopedAddress(ascii: decodedBytes)
                self = .ipv6(scopedAddress)
                return
            } catch {
                let innerString = String(decoding: innerBytes, as: UTF8.self)
                throw Error.invalidIPv6(innerString, reason: "Invalid IPv6 address")
            }
        }

        // Try to parse as IPv4 address
        do {
            let ipv4Address = try RFC_791.IPv4.Address(ascii: bytes)
            self = .ipv4(ipv4Address)
            return
        } catch {
            // Not a valid IPv4 - continue to registered name
        }

        // Otherwise treat as registered name
        // Validate registered name characters at byte level
        for byte in bytes {
            // unreserved: ALPHA / DIGIT / "-" / "." / "_" / "~"
            // sub-delims: "!" / "$" / "&" / "'" / "(" / ")" / "*" / "+" / "," / ";" / "="
            // plus percent-encoding "%"
            let isUnreserved =
                byte.ascii.isLetter || byte.ascii.isDigit
                || byte == 0x2D || byte == 0x2E || byte == 0x5F || byte == 0x7E  // - . _ ~
            let isSubDelim =
                byte == 0x21 || byte == 0x24 || byte == 0x26 || byte == 0x27  // ! $ & '
                || byte == 0x28 || byte == 0x29 || byte == 0x2A || byte == 0x2B  // ( ) * +
                || byte == 0x2C || byte == 0x3B || byte == 0x3D  // , ; =
            let isPercent = byte == 0x25  // %

            guard isUnreserved || isSubDelim || isPercent else {
                throw Error.invalidCharacter(
                    string,
                    byte: byte,
                    reason:
                        "Only unreserved, sub-delims, and percent-encoded allowed in registered name"
                )
            }
        }

        // Normalize to lowercase per RFC 3986 Section 6.2.2.1
        self = .registeredName(string.lowercased())
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
    /// For IPv6, this includes the surrounding brackets and percent-encoded zone.
    /// For IPv4 and registered names, returns the value as-is.
    public var rawValue: String {
        String(decoding: [UInt8](self), as: UTF8.self)
    }

    /// Returns true if this is a loopback address
    public var isLoopback: Bool {
        switch self {
        case .ipv4(let address):
            // IPv4 loopback: 127.0.0.0/8 (any 127.x.x.x)
            return address.octets.0 == 127
        case .ipv6(let scopedAddress):
            return scopedAddress.address.isLoopback
        case .registeredName(let name):
            return name == "localhost"
        }
    }

    /// The IPv4 address if this host is an IPv4 address
    public var ipv4Address: RFC_791.IPv4.Address? {
        if case .ipv4(let address) = self {
            return address
        }
        return nil
    }

    /// The IPv6 scoped address if this host is an IPv6 address
    public var ipv6ScopedAddress: RFC_4007.IPv6.ScopedAddress? {
        if case .ipv6(let scopedAddress) = self {
            return scopedAddress
        }
        return nil
    }

    /// The IPv6 address if this host is an IPv6 address (without zone)
    public var ipv6Address: RFC_4291.IPv6.Address? {
        if case .ipv6(let scopedAddress) = self {
            return scopedAddress.address
        }
        return nil
    }

    /// The registered name if this host is a registered name
    public var registeredNameValue: String? {
        if case .registeredName(let name) = self {
            return name
        }
        return nil
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
