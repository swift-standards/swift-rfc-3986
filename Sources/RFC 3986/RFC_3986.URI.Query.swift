public import INCITS_4_1986

// MARK: - URI RFC_3986.URI.Query

extension RFC_3986.URI {
    /// URI query component per RFC 3986 Section 3.4
    ///
    /// The query component contains non-hierarchical data that, along with data in the path component,
    /// serves to identify a resource within the scope of the URI's scheme and authority.
    ///
    /// RFC_3986.URI.Query parameters are case-sensitive and order-preserving. Multiple parameters with the same
    /// key are allowed (e.g., "tag=swift&tag=ios").
    ///
    /// ## Example
    /// ```swift
    /// // Create from parameters
    /// let query = try RFC_3986.URI.Query([
    ///     ("page", "1"),
    ///     ("limit", "20"),
    ///     ("sort", "name")
    /// ])
    /// print(query.string) // "page=1&limit=20&sort=name"
    ///
    /// // Access parameters
    /// let pages = query["page"] // ["1"]
    ///
    /// // Multiple values for same key
    /// let tags = try RFC_3986.URI.Query([
    ///     ("tag", "swift"),
    ///     ("tag", "ios")
    /// ])
    /// print(tags["tag"]) // ["swift", "ios"]
    ///
    /// // Parse from string
    /// let parsed = try RFC_3986.URI.Query("search=test&category=docs")
    /// ```
    ///
    /// ## RFC 3986 Reference
    /// ```
    /// query = *( pchar / "/" / "?" )
    /// ```
    public struct Query: Sendable, Codable, Hashable, Equatable {
        /// RawValue type for RawRepresentable conformance
        public typealias RawValue = String

        /// The raw query string
        public let rawValue: String

        /// The query parameters as an array of key-value pairs
        ///
        /// Uses an array to preserve order and allow duplicate keys.
        /// Values can be nil to support keys without values (e.g., "flag" in "?flag&other=value")
        public let parameters: [(key: String, value: String?)]

        /// Creates a query WITHOUT validation
        ///
        /// **Warning**: Bypasses RFC 3986 validation.
        /// Only use with compile-time constants or pre-validated values.
        ///
        /// - Parameters:
        ///   - unchecked: Void parameter to prevent accidental use
        ///   - rawValue: The raw query value (unchecked)
        ///   - parameters: The parsed parameters (unchecked)
        init(
            __unchecked _: Void,
            rawValue: String,
            parameters: [(key: String, value: String?)]
        ) {
            self.rawValue = rawValue
            self.parameters = parameters
        }
    }
}

// MARK: - Serializable

extension RFC_3986.URI.Query: UInt8.ASCII.Serializable {
    /// Serialize query to ASCII bytes
    public static func serialize<Buffer: RangeReplaceableCollection>(
        ascii query: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == UInt8 {
        buffer.append(contentsOf: query.rawValue.utf8)
    }

    /// Parses query from ASCII bytes (CANONICAL PRIMITIVE)
    ///
    /// This is the primitive parser that works at the byte level.
    /// RFC 3986 queries follow the pattern: *( pchar / "/" / "?" )
    ///
    /// ## Category Theory
    ///
    /// This is the fundamental parsing transformation:
    /// - **Domain**: [UInt8] (ASCII bytes)
    /// - **Codomain**: RFC_3986.URI.Query (structured data)
    ///
    /// ## RFC 3986 Section 3.4
    ///
    /// ```
    /// query = *( pchar / "/" / "?" )
    /// ```
    ///
    /// - Parameter bytes: The ASCII byte representation of the query
    /// - Throws: `RFC_3986.URI.Query.Error` if the bytes are malformed
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void) throws(Error)
    where Bytes.Element == UInt8 {
        // Empty query is allowed
        if bytes.isEmpty {
            self.init(__unchecked: (), rawValue: "", parameters: [])
            return
        }

        // Validate query characters at byte level
        var i = bytes.startIndex
        while i < bytes.endIndex {
            let byte = bytes[i]

            // Check for percent-encoding
            if byte == 0x25 {  // '%'
                let next1 = bytes.index(after: i)
                guard next1 < bytes.endIndex else {
                    throw Error.invalidPercentEncoding(
                        String(decoding: bytes, as: UTF8.self),
                        reason: "'%' must be followed by 2 hex digits"
                    )
                }
                let next2 = bytes.index(after: next1)
                guard next2 < bytes.endIndex else {
                    throw Error.invalidPercentEncoding(
                        String(decoding: bytes, as: UTF8.self),
                        reason: "'%' must be followed by 2 hex digits"
                    )
                }

                guard bytes[next1].ascii.isHexDigit && bytes[next2].ascii.isHexDigit else {
                    throw Error.invalidPercentEncoding(
                        String(decoding: bytes, as: UTF8.self),
                        reason: "Invalid hex digits after '%'"
                    )
                }

                i = bytes.index(after: next2)
                continue
            }

            // Check for newlines (invalid in queries)
            if byte == 0x0A || byte == 0x0D {
                throw Error.invalidCharacter(
                    String(decoding: bytes, as: UTF8.self),
                    byte: byte,
                    reason: "Query cannot contain newlines"
                )
            }

            // Check for hash (invalid in queries - separates fragment)
            if byte == 0x23 {  // '#'
                throw Error.invalidCharacter(
                    String(decoding: bytes, as: UTF8.self),
                    byte: byte,
                    reason: "Query cannot contain '#' (use for fragment instead)"
                )
            }

            i = bytes.index(after: i)
        }

        let queryString = String(decoding: bytes, as: UTF8.self)

        // Parse parameters
        let pairs = queryString.split(separator: "&", omittingEmptySubsequences: false)
        var parameters: [(String, String?)] = []

        for pair in pairs {
            if let equalIndex = pair.firstIndex(of: "=") {
                let key = String(pair[..<equalIndex])
                let value = String(pair[pair.index(after: equalIndex)...])

                // Validate key is not empty
                guard !key.isEmpty else {
                    throw Error.emptyKey
                }

                parameters.append((key, value))
            } else {
                // Key without value
                let key = String(pair)
                guard !key.isEmpty else {
                    throw Error.emptyKey
                }
                parameters.append((key, nil))
            }
        }

        self.init(__unchecked: (), rawValue: queryString, parameters: parameters)
    }
}

// MARK: - Protocol Conformances

extension RFC_3986.URI.Query: UInt8.ASCII.RawRepresentable {}
extension RFC_3986.URI.Query: CustomStringConvertible {}

// MARK: - Public Initializers

extension RFC_3986.URI.Query {
    /// The query parameters as an array of key-value pairs
    ///
    /// Uses an array to preserve order and allow duplicate keys.
    /// Values can be nil to support keys without values (e.g., "flag" in "?flag&other=value")
    private var _legacyParameters: [(key: String, value: String?)] { parameters }

    /// Creates a query from an array of parameters
    ///
    /// - Parameter parameters: The query parameters
    /// - Throws: `RFC_3986.URI.Query.Error` if parameters contain invalid characters
    public init(_ parameters: [(String, String?)] = []) throws(Error) {
        // Build query string from parameters
        let queryString = parameters.map { key, value in
            if let value = value {
                return "\(key)=\(value)"
            } else {
                return key
            }
        }.joined(separator: "&")

        // Use byte parser for validation
        try self.init(ascii: Array(queryString.utf8))
    }

    /// Creates a query without validation
    ///
    /// This is an internal optimization for static constants and validated values.
    ///
    /// - Parameter parameters: The query parameters (must be valid, not validated)
    /// - Warning: This skips validation. For public use, use `try!` with
    ///   the throwing initializer to make the risk explicit.
    internal init(unchecked parameters: [(String, String?)]) {
        let queryString = parameters.map { key, value in
            if let value = value {
                return "\(key)=\(value)"
            } else {
                return key
            }
        }.joined(separator: "&")
        self.init(__unchecked: (), rawValue: queryString, parameters: parameters)
    }

    /// The string representation of the query
    ///
    /// Returns the query in the form "key1=value1&key2=value2" (without leading "?").
    /// Keys without values are rendered as just the key name.
    public var string: String {
        parameters.map { key, value in
            if let value = value {
                return "\(key)=\(value)"
            } else {
                return key
            }
        }.joined(separator: "&")
    }

    /// Returns true if the query has no parameters
    public var isEmpty: Bool {
        parameters.isEmpty
    }

    /// The number of parameters
    public var count: Int {
        parameters.count
    }

    /// Gets all values for a given key
    ///
    /// - Parameter key: The parameter key to look up
    /// - Returns: An array of values for that key (may be empty)
    public subscript(key: String) -> [String?] {
        parameters.filter { $0.key == key }.map { $0.value }
    }

    /// Gets the first value for a given key
    ///
    /// - Parameter key: The parameter key to look up
    /// - Returns: The first value for that key, or nil if not found
    public func first(for key: some StringProtocol) -> String? {
        parameters.first { $0.key == key }?.value ?? nil
    }

    /// Adds a parameter to the query
    ///
    /// - Parameters:
    ///   - key: The parameter key
    ///   - value: The parameter value (nil for keys without values)
    /// - Returns: A new query with the parameter added
    /// - Throws: `RFC_3986.Error.invalidComponent` if the parameter is invalid
    public func appending(
        key: some StringProtocol,
        value: (some StringProtocol)?
    ) throws -> RFC_3986.URI.Query {
        var newParameters = parameters
        newParameters.append((String(key), value.map { String($0) }))
        return try RFC_3986.URI.Query(newParameters)
    }

    /// Returns a new query with all parameters for a given key removed
    ///
    /// - Parameter key: The parameter key to remove
    /// - Returns: A new query without parameters matching the key
    public func removing(key: some StringProtocol) -> RFC_3986.URI.Query {
        let filtered = parameters.filter { $0.key != key }
        return RFC_3986.URI.Query(unchecked: filtered)
    }

    /// All unique keys in the query
    public var keys: Set<String> {
        Set(parameters.map { $0.key })
    }
}

// MARK: - Collection

extension RFC_3986.URI.Query: Collection {
    public typealias Index = Array<(key: String, value: String?)>.Index
    public typealias Element = (key: String, value: String?)

    public var startIndex: Index {
        parameters.startIndex
    }

    public var endIndex: Index {
        parameters.endIndex
    }

    public subscript(position: Index) -> Element {
        parameters[position]
    }

    public func index(after i: Index) -> Index {
        parameters.index(after: i)
    }
}

// MARK: - ExpressibleByArrayLiteral

extension RFC_3986.URI.Query: ExpressibleByArrayLiteral {
    /// Creates a query from an array literal of key-value tuples
    ///
    /// Example:
    /// ```swift
    /// let query: RFC_3986.URI.Query = [("page", "1"), ("limit", "20")]
    /// ```
    public init(arrayLiteral elements: (String, String?)...) {
        self.init(unchecked: elements)
    }
}

// MARK: - ExpressibleByDictionaryLiteral

extension RFC_3986.URI.Query: ExpressibleByDictionaryLiteral {
    /// Creates a query from a dictionary literal
    ///
    /// Example:
    /// ```swift
    /// let query: RFC_3986.URI.Query = ["page": "1", "limit": "20"]
    /// ```
    ///
    /// - Note: Dictionary literals don't preserve order or allow duplicate keys.
    ///   Use array literal syntax for those cases.
    public init(dictionaryLiteral elements: (String, String)...) {
        self.init(unchecked: elements.map { ($0, $1 as String?) })
    }
}

// MARK: - Hashable

extension RFC_3986.URI.Query {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue == rhs.rawValue
    }

    public static func == (lhs: Self, rhs: String) -> Bool {
        lhs.rawValue == rhs
    }
}

// MARK: - Codable

extension RFC_3986.URI.Query {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        do {
            try self.init(string)
        } catch {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid query: \(error)"
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
