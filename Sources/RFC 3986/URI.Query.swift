
// MARK: - URI Query

extension RFC_3986.URI {
    /// URI query component per RFC 3986 Section 3.4
    ///
    /// The query component contains non-hierarchical data that, along with data in the path component,
    /// serves to identify a resource within the scope of the URI's scheme and authority.
    ///
    /// Query parameters are case-sensitive and order-preserving. Multiple parameters with the same
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
    public struct Query: Sendable {
        /// The query parameters as an array of key-value pairs
        ///
        /// Uses an array to preserve order and allow duplicate keys.
        /// Values can be nil to support keys without values (e.g., "flag" in "?flag&other=value")
        public let parameters: [(key: String, value: String?)]

        /// Creates a query from an array of parameters
        ///
        /// - Parameter parameters: The query parameters
        /// - Throws: `RFC_3986.Error.invalidComponent` if parameters contain invalid characters
        public init(_ parameters: [(String, String?)] = []) throws {
            // Basic validation - full validation would check query character set
            for (key, value) in parameters {
                if key.isEmpty {
                    throw RFC_3986.Error.invalidComponent("Query parameter key cannot be empty")
                }
                // Check for obviously invalid characters
                if key.contains(where: { $0.isNewline }) {
                    throw RFC_3986.Error.invalidComponent("Query key contains newline")
                }
                if let value = value, value.contains(where: { $0.isNewline }) {
                    throw RFC_3986.Error.invalidComponent("Query value contains newline")
                }
            }

            self.parameters = parameters
        }

        /// Creates a query without validation
        ///
        /// This is an internal optimization for static constants and validated values.
        ///
        /// - Parameter parameters: The query parameters (must be valid, not validated)
        /// - Warning: This skips validation. For public use, use `try!` with
        ///   the throwing initializer to make the risk explicit.
        internal init(unchecked parameters: [(String, String?)]) {
            self.parameters = parameters
        }

        /// Creates a query from a query string
        ///
        /// - Parameter string: The query string (without leading "?")
        /// - Throws: `RFC_3986.Error.invalidComponent` if the query string is invalid
        ///
        /// Parses query strings in the form "key1=value1&key2=value2".
        /// Supports keys without values ("flag" in "?flag&other=value").
        public init(_ string: String) throws {
            guard !string.isEmpty else {
                self.init(unchecked: [])
                return
            }

            let pairs = string.split(separator: "&", omittingEmptySubsequences: false)
            var parameters: [(String, String?)] = []

            for pair in pairs {
                if let equalIndex = pair.firstIndex(of: "=") {
                    let key = String(pair[..<equalIndex])
                    let value = String(pair[pair.index(after: equalIndex)...])
                    parameters.append((key, value))
                } else {
                    // Key without value
                    parameters.append((String(pair), nil))
                }
            }

            try self.init(parameters)
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
        public func first(for key: String) -> String? {
            parameters.first { $0.key == key }?.value ?? nil
        }

        /// Adds a parameter to the query
        ///
        /// - Parameters:
        ///   - key: The parameter key
        ///   - value: The parameter value (nil for keys without values)
        /// - Returns: A new query with the parameter added
        /// - Throws: `RFC_3986.Error.invalidComponent` if the parameter is invalid
        public func appending(key: String, value: String?) throws -> Query {
            var newParameters = parameters
            newParameters.append((key, value))
            return try Query(newParameters)
        }

        /// Returns a new query with all parameters for a given key removed
        ///
        /// - Parameter key: The parameter key to remove
        /// - Returns: A new query without parameters matching the key
        public func removing(key: String) -> Query {
            let filtered = parameters.filter { $0.key != key }
            return Query(unchecked: filtered)
        }

        /// All unique keys in the query
        public var keys: Set<String> {
            Set(parameters.map { $0.key })
        }
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

// MARK: - Equatable

extension RFC_3986.URI.Query: Equatable {
    public static func == (lhs: RFC_3986.URI.Query, rhs: RFC_3986.URI.Query) -> Bool {
        guard lhs.parameters.count == rhs.parameters.count else { return false }
        for (lhsParam, rhsParam) in zip(lhs.parameters, rhs.parameters) {
            if lhsParam.key != rhsParam.key || lhsParam.value != rhsParam.value {
                return false
            }
        }
        return true
    }
}

// MARK: - Hashable

extension RFC_3986.URI.Query: Hashable {
    public func hash(into hasher: inout Hasher) {
        for param in parameters {
            hasher.combine(param.key)
            hasher.combine(param.value)
        }
    }
}

// MARK: - CustomStringConvertible

extension RFC_3986.URI.Query: CustomStringConvertible {
    public var description: String {
        string
    }
}

// MARK: - Codable

extension RFC_3986.URI.Query: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        try self.init(string)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(string)
    }
}
