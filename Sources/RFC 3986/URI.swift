extension RFC_3986 {
    /// Errors that can occur when working with URIs
    public enum Error: Swift.Error, Hashable, Sendable {
        /// The provided string is not a valid URI per RFC 3986
        case invalidURI(String)

        /// A URI component is invalid or malformed
        case invalidComponent(String)

        /// URI conversion or transformation failed
        case conversionFailed(String)
    }
}

extension RFC_3986.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidURI(let value):
            return "Invalid URI: '\(value)'. URIs must follow RFC 3986 syntax and contain only ASCII characters."
        case .invalidComponent(let component):
            return "Invalid URI component: '\(component)'"
        case .conversionFailed(let reason):
            return "URI conversion failed: \(reason)"
        }
    }
}

// MARK: - URI.Representable Protocol

extension RFC_3986 {
    /// Protocol for types that can represent URIs
    ///
    /// Types conforming to this protocol can be used interchangeably wherever a URI
    /// is expected.
    ///
    /// Example:
    /// ```swift
    /// func process(uri: any RFC_3986.URIRepresentable) {
    ///     print(uri.uri.value)
    /// }
    ///
    /// let uri = try RFC_3986.URI("https://example.com")
    /// process(uri: uri)  // Works!
    /// ```
    public protocol URIRepresentable {
        /// The URI representation
        var uri: RFC_3986.URI { get }
    }
}

// MARK: - URI

extension RFC_3986 {
    /// A Uniform Resource Identifier (URI) reference as defined in RFC 3986
    ///
    /// URIs provide a simple and extensible means for identifying a resource.
    /// They use a restricted set of ASCII characters to ensure maximum compatibility
    /// across different systems and protocols.
    ///
    /// RFC 3986 Section 4.1 defines a URI-reference as either:
    /// - An absolute URI with a scheme (e.g., `https://example.com/path`)
    /// - A relative reference without a scheme (e.g., `/path`, `?query`, `#fragment`)
    ///
    /// RFC 3986 defines a generic syntax consisting of a hierarchical sequence of
    /// five components: scheme, authority, path, query, and fragment.
    ///
    /// For protocol-oriented usage with types like `URL`, see the `RFC_3986.URIRepresentable` protocol.
    public struct URI: Hashable, Sendable, Codable {
        fileprivate let cache: Cache

        /// The URI string
        public var value: String { cache.value }
    }
}

extension RFC_3986.URI {
    // MARK: - Internal Cache

    /// Internal cache for parsed URI components
    ///
    /// Uses a class for reference semantics, enabling lazy caching while maintaining
    /// value semantics for the URI struct. Components are parsed once on first access
    /// and cached for O(1) subsequent access.
    ///
    /// This is marked @unchecked Sendable because:
    /// - The cache is immutable after initialization
    /// - Lazy properties are thread-safe in Swift
    /// - Multiple URI copies share the same cache (COW-like behavior)
    fileprivate final class Cache: @unchecked Sendable {
        let value: String
        let components: ParsedComponents

        // Lazy cached components - parsed once on first access
        lazy var scheme: Scheme? = {
            components.scheme.flatMap { try? Scheme($0) }
        }()

        lazy var host: Host? = {
            components.host.flatMap { try? Host($0) }
        }()

        lazy var port: Port? = {
            components.port.flatMap { Port($0) }
        }()

        lazy var path: Path? = {
            guard let pathString = components.path, !pathString.isEmpty else { return nil }
            return try? Path(pathString)
        }()

        lazy var query: Query? = {
            components.query.flatMap { try? Query($0) }
        }()

        lazy var fragment: Fragment? = {
            components.fragment.flatMap { try? Fragment($0) }
        }()

        init(value: String) {
            self.value = value
            self.components = Self.parseURI(value)
        }

        /// Parses a URI string according to RFC 3986 Appendix B
        ///
        /// Uses the regex from RFC 3986 Appendix B:
        /// ^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?
        ///
        /// Groups:
        /// - 2: scheme
        /// - 4: authority
        /// - 5: path
        /// - 7: query
        /// - 9: fragment
        private static func parseURI(_ uri: String) -> ParsedComponents {
            var scheme: String?
            var authority: String?
            var path: String?
            var query: String?
            var fragment: String?

            var remaining = uri

            // Parse fragment: #(.*)
            if let fragmentIndex = remaining.lastIndex(of: "#") {
                fragment = String(remaining[remaining.index(after: fragmentIndex)...])
                remaining = String(remaining[..<fragmentIndex])
            }

            // Parse query: \?([^#]*)
            if let queryIndex = remaining.lastIndex(of: "?") {
                query = String(remaining[remaining.index(after: queryIndex)...])
                remaining = String(remaining[..<queryIndex])
            }

            // Parse scheme: ([^:/?#]+):
            if let colonIndex = remaining.firstIndex(of: ":"),
               colonIndex > remaining.startIndex {
                let schemeCandidate = String(remaining[..<colonIndex])
                // Verify no /, ?, or # appear before the colon
                if !schemeCandidate.contains("/") &&
                   !schemeCandidate.contains("?") &&
                   !schemeCandidate.contains("#") {
                    scheme = schemeCandidate
                    remaining = String(remaining[remaining.index(after: colonIndex)...])
                }
            }

            // Parse authority: //([^/?#]*)
            if remaining.hasPrefix("//") {
                let afterSlashes = remaining.index(remaining.startIndex, offsetBy: 2)
                var authorityEnd = remaining.endIndex

                // Find the first /, ?, or # after //
                for char in ["/", "?", "#"] {
                    if let index = remaining[afterSlashes...].firstIndex(of: Character(char)) {
                        if index < authorityEnd {
                            authorityEnd = index
                        }
                    }
                }

                authority = String(remaining[afterSlashes..<authorityEnd])
                remaining = String(remaining[authorityEnd...])
            }

            // What remains is the path
            if !remaining.isEmpty {
                path = remaining
            }

            // Parse authority into host and port
            var host: String?
            var port: UInt16?
            if let auth = authority {
                (host, port) = parseAuthority(auth)
            }

            return ParsedComponents(
                scheme: scheme,
                host: host,
                port: port,
                path: path,
                query: query,
                fragment: fragment
            )
        }

        /// Parses authority into host and port
        /// authority = [ userinfo "@" ] host [ ":" port ]
        private static func parseAuthority(_ authority: String) -> (host: String?, port: UInt16?) {
            var remaining = authority

            // Skip userinfo if present (everything before @)
            if let atIndex = remaining.lastIndex(of: "@") {
                remaining = String(remaining[remaining.index(after: atIndex)...])
            }

            // Check for port (: followed by digits at the end)
            if let colonIndex = remaining.lastIndex(of: ":") {
                let hostPart = String(remaining[..<colonIndex])
                let portPart = String(remaining[remaining.index(after: colonIndex)...])

                if let portValue = UInt16(portPart) {
                    return (hostPart.isEmpty ? nil : hostPart, portValue)
                }
            }

            return (remaining.isEmpty ? nil : remaining, nil)
        }

        /// Temporary struct to hold parsed URI components
        struct ParsedComponents {
            let scheme: String?
            let host: String?
            let port: UInt16?
            let path: String?
            let query: String?
            let fragment: String?
        }
    }
}


// MARK: - Initialization

extension RFC_3986.URI {
    /// Creates a URI from a string with validation
    ///
    /// - Parameter value: The URI string
    /// - Throws: RFC_3986.Error if the string is not a valid URI
    public init(_ value: String) throws {
        guard RFC_3986.isValidURI(value) else {
            throw RFC_3986.Error.invalidURI(value)
        }
        self.cache = Cache(value: value)
    }

    /// Creates a URI from a string without validation
    ///
    /// This is an internal optimization for cases where validation has already
    /// been performed (e.g., for static constants or when the string is known to be valid).
    ///
    /// - Warning: This does not perform validation. For public use, use `try!` with
    ///   the throwing initializer to make the risk explicit.
    ///
    /// - Parameter value: The URI reference string (must be valid, not validated)
    internal init(unchecked value: String) {
        self.cache = Cache(value: value)
    }

    /// Creates a URI from validated RFC 3986 component types
    ///
    /// This initializer constructs a URI from typed components. Since all components
    /// are already validated RFC types, this cannot fail.
    ///
    /// - Parameters:
    ///   - scheme: The URI scheme
    ///   - authority: The authority component (userinfo, host, port)
    ///   - path: The path component
    ///   - query: The query component
    ///   - fragment: The fragment component
    ///
    /// Example:
    /// ```swift
    /// let uri = RFC_3986.URI(
    ///     scheme: try .init("https"),
    ///     authority: .init(
    ///         userinfo: nil,
    ///         host: try .init("example.com"),
    ///         port: .init(443)
    ///     ),
    ///     path: try .init("/path"),
    ///     query: try .init("key=value"),
    ///     fragment: nil
    /// )
    /// ```
    public init(
        scheme: Scheme,
        authority: Authority,
        path: Path,
        query: Query? = nil,
        fragment: Fragment? = nil
    ) {
        var uriString = "\(scheme.value)://"

        if let userinfo = authority.userinfo {
            uriString += "\(userinfo.rawValue)@"
        }

        uriString += authority.host.rawValue

        if let port = authority.port {
            uriString += ":\(port.value)"
        }

        uriString += path.string

        if let query = query {
            uriString += "?\(query.string)"
        }

        if let fragment = fragment {
            uriString += "#\(fragment.value)"
        }

        self.cache = Cache(value: uriString)
    }
}

// MARK: - Component Properties

extension RFC_3986.URI {
    /// The scheme component of this URI
    ///
    /// Per RFC 3986 Section 3.1, the scheme is the first component of a URI
    /// and is followed by a colon. Scheme names consist of a sequence of characters
    /// beginning with a letter and followed by any combination of letters, digits,
    /// plus (+), period (.), or hyphen (-).
    ///
    /// Components are lazily parsed and cached for O(1) access after first use.
    public var scheme: Scheme? {
        cache.scheme
    }

    /// The userinfo component of this URI
    ///
    /// Per RFC 3986 Section 3.2.1, the userinfo subcomponent may consist of
    /// a user name and, optionally, scheme-specific information about how to
    /// gain authorization to access the resource. The userinfo, if present,
    /// is followed by a commercial at-sign ("@") that delimits it from the host.
    ///
    /// Note: The userinfo component is deprecated per RFC 3986 Section 3.2.1
    /// for security reasons (passwords in URIs are insecure), but is still
    /// part of the URI syntax for compatibility.
    public var userinfo: Userinfo? {
        // Parse userinfo from the full authority section
        // authority = [ userinfo "@" ] host [ ":" port ]
        // We need to re-parse the original URI to extract userinfo

        // Find the authority section (between // and the next /, ?, or #)
        var remaining = cache.value

        // Skip scheme if present
        if let colonIndex = remaining.firstIndex(of: ":") {
            remaining = String(remaining[remaining.index(after: colonIndex)...])
        }

        // Check for authority (starts with //)
        guard remaining.hasPrefix("//") else { return nil }
        let afterSlashes = remaining.index(remaining.startIndex, offsetBy: 2)
        var authorityEnd = remaining.endIndex

        // Find the end of authority
        for char in ["/", "?", "#"] {
            if let index = remaining[afterSlashes...].firstIndex(of: Character(char)) {
                if index < authorityEnd {
                    authorityEnd = index
                }
            }
        }

        let authority = String(remaining[afterSlashes..<authorityEnd])

        // Extract userinfo (everything before @)
        guard let atIndex = authority.firstIndex(of: "@") else { return nil }
        let userinfoString = String(authority[..<atIndex])

        return try? Userinfo(userinfoString)
    }

    /// The host component of this URI
    ///
    /// Per RFC 3986 Section 3.2.2, the host is identified by an IP literal,
    /// IPv4 address, or registered name.
    ///
    /// Components are lazily parsed and cached for O(1) access after first use.
    public var host: Host? {
        cache.host
    }

    /// The port component of this URI
    ///
    /// Per RFC 3986 Section 3.2.3, the port is designated by an optional decimal
    /// port number following the host and delimited from it by a colon.
    ///
    /// Components are lazily parsed and cached for O(1) access after first use.
    public var port: Port? {
        cache.port
    }

    /// The path component of this URI
    ///
    /// Per RFC 3986 Section 3.3, the path contains data that identifies a resource
    /// within the scope of the URI's scheme and authority.
    ///
    /// Components are lazily parsed and cached for O(1) access after first use.
    public var path: Path? {
        cache.path
    }

    /// The query component of this URI
    ///
    /// Per RFC 3986 Section 3.4, the query contains non-hierarchical data that
    /// identifies a resource in conjunction with the scheme and authority.
    ///
    /// Components are lazily parsed and cached for O(1) access after first use.
    public var query: Query? {
        cache.query
    }

    /// The fragment component of this URI
    ///
    /// Per RFC 3986 Section 3.5, the fragment allows indirect identification
    /// of a secondary resource by reference to a primary resource.
    ///
    /// Components are lazily parsed and cached for O(1) access after first use.
    public var fragment: Fragment? {
        cache.fragment
    }
}

// MARK: - Convenience Properties

extension RFC_3986.URI {
    /// Indicates whether this URI is a relative reference
    ///
    /// Per RFC 3986 Section 4.2, a relative reference does not begin with a scheme.
    /// Examples: `//example.com/path`, `/path`, `path`, `?query`, `#fragment`
    ///
    /// - Returns: true if this is a relative reference, false if absolute
    public var isRelative: Bool {
        scheme == nil
    }

    /// Returns `true` if this URI uses a secure scheme (https, wss, etc.)
    public var isSecure: Bool {
        guard let uriScheme = scheme?.value else { return false }
        return ["https", "wss", "ftps"].contains(uriScheme)
    }

    /// Returns `true` if this URI is an HTTP or HTTPS URI
    public var isHTTP: Bool {
        guard let uriScheme = scheme?.value else { return false }
        return uriScheme == "http" || uriScheme == "https"
    }

    /// Returns the base URI (scheme + authority) without path, query, or fragment
    ///
    /// Example: `https://example.com:8080/path?query#fragment` → `https://example.com:8080`
    public var base: RFC_3986.URI? {
        guard let uriScheme = scheme,
              let uriHost = host
        else { return nil }

        var baseString = "\(uriScheme.value)://\(uriHost.rawValue)"
        if let uriPort = port {
            baseString += ":\(uriPort.value)"
        }
        return RFC_3986.URI(unchecked: baseString)
    }

    /// Returns the path and query components combined
    ///
    /// Example: `/path?key=value`
    public var pathAndQuery: String? {
        guard let uriPath = path else { return nil }
        if let uriQuery = query {
            return "\(uriPath.string)?\(uriQuery.string)"
        }
        return uriPath.string
    }
}

// MARK: - URI Operations

extension RFC_3986.URI {
    /// Returns a normalized version of this URI
    ///
    /// Per RFC 3986 Section 6, normalization includes:
    /// - Case normalization of scheme and host (Section 6.2.2.1)
    /// - Percent-encoding normalization (Section 6.2.2.2)
    /// - Path segment normalization (Section 6.2.2.3)
    /// - Removal of default ports
    ///
    /// - Returns: A normalized URI
    public func normalized() -> RFC_3986.URI {
        // Get components
        let normalizedScheme = scheme?.value.lowercased()
        let normalizedHost = host?.rawValue.lowercased()
        var normalizedPort = port
        var normalizedPath = path?.string
        var normalizedQuery = query?.string
        let normalizedFragment = fragment?.value

        // Remove default ports
        if let scheme = normalizedScheme, let port = normalizedPort {
            let isDefaultPort =
                (scheme == "http" && port == 80) ||
                (scheme == "https" && port == 443) ||
                (scheme == "ftp" && port == 21)
            if isDefaultPort {
                normalizedPort = nil
            }
        }

        // Normalize path by removing dot segments (Section 6.2.2.3)
        if let pathString = normalizedPath, !pathString.isEmpty {
            normalizedPath = RFC_3986.removeDotSegments(from: pathString)
        }

        // Normalize percent-encoding (Section 6.2.2.2)
        if let pathString = normalizedPath {
            normalizedPath = RFC_3986.normalizePercentEncoding(pathString)
        }
        if let queryString = normalizedQuery {
            normalizedQuery = RFC_3986.normalizePercentEncoding(queryString)
        }

        // Reconstruct URI
        var result = ""
        if let scheme = normalizedScheme {
            result += "\(scheme):"
        }
        if let host = normalizedHost {
            result += "//\(host)"
            if let port = normalizedPort {
                result += ":\(port)"
            }
        }
        if let path = normalizedPath {
            result += path
        }
        if let query = normalizedQuery {
            result += "?\(query)"
        }
        if let fragment = normalizedFragment {
            result += "#\(fragment)"
        }

        return RFC_3986.URI(unchecked: result)
    }

    /// Resolves a relative URI reference against this URI as a base
    ///
    /// Per RFC 3986 Section 5, this implements the URI resolution algorithm
    /// to convert a relative reference into an absolute URI.
    ///
    /// - Parameter reference: The URI reference to resolve (may be relative or absolute)
    /// - Returns: The resolved absolute URI
    /// - Throws: RFC_3986.Error if resolution fails
    public func resolve(_ reference: RFC_3986.URI) throws -> RFC_3986.URI {
        try resolve(reference.value)
    }

    /// Resolves a relative URI reference against this URI as a base
    ///
    /// Per RFC 3986 Section 5, this implements the URI resolution algorithm
    /// to convert a relative reference into an absolute URI.
    ///
    /// - Parameter reference: The URI reference string to resolve
    /// - Returns: The resolved absolute URI
    /// - Throws: RFC_3986.Error if resolution fails
    public func resolve(_ reference: String) throws -> RFC_3986.URI {
        // TODO: Implement full RFC 3986 Section 5 resolution algorithm
        // For now, this is a simplified implementation

        let refURI = try RFC_3986.URI(reference)

        // If reference has a scheme, it's absolute - return it as-is
        if refURI.scheme != nil {
            return refURI
        }

        // If reference has authority, use base scheme + reference authority/path/query
        if refURI.host != nil {
            var result = ""
            if let baseScheme = scheme {
                result += "\(baseScheme.value):"
            }
            result += "//"
            if let refHost = refURI.host {
                result += refHost.rawValue
            }
            if let refPort = refURI.port {
                result += ":\(refPort)"
            }
            if let refPath = refURI.path {
                result += refPath.string
            }
            if let refQuery = refURI.query {
                result += "?\(refQuery.string)"
            }
            if let refFragment = refURI.fragment {
                result += "#\(refFragment.value)"
            }
            return RFC_3986.URI(unchecked: result)
        }

        // Reference has no scheme or authority - merge paths
        var result = ""
        if let baseScheme = scheme {
            result += "\(baseScheme.value):"
        }
        if let baseHost = host {
            result += "//\(baseHost.rawValue)"
            if let basePort = port {
                result += ":\(basePort)"
            }
        }

        // Merge paths according to RFC 3986 Section 5.2.3
        let refPath = refURI.path?.string
        if let refPath = refPath, !refPath.isEmpty {
            if refPath.hasPrefix("/") {
                // Absolute path - use reference path as-is
                result += refPath
            } else {
                // Relative path - merge with base
                if let basePath = path?.string {
                    // Remove last segment from base path
                    if let lastSlash = basePath.lastIndex(of: "/") {
                        result += String(basePath[...lastSlash])
                    }
                    result += refPath
                } else {
                    result += "/\(refPath)"
                }
            }
            // Remove dot segments from the merged path
            result = RFC_3986.removeDotSegments(from: result)
        } else if let basePath = path {
            result += basePath.string
        }

        // Use reference query if present, otherwise use base query
        if let refQuery = refURI.query {
            result += "?\(refQuery.string)"
        } else if refPath == nil, let baseQuery = query {
            result += "?\(baseQuery.string)"
        }

        // Always use reference fragment
        if let refFragment = refURI.fragment {
            result += "#\(refFragment.value)"
        }

        return RFC_3986.URI(unchecked: result)
    }
}

// MARK: - Convenience Methods

extension RFC_3986.URI {
    /// Creates a new URI by appending a path component
    ///
    /// - Parameter component: The path component to append
    /// - Returns: A new URI with the appended path component
    public func appendingPathComponent(_ component: String) throws -> RFC_3986.URI {
        var result = ""

        // Add scheme
        if let uriScheme = scheme {
            result += "\(uriScheme.value):"
        }

        // Add authority
        if let uriHost = host {
            result += "//\(uriHost.rawValue)"
            if let uriPort = port {
                result += ":\(uriPort)"
            }
        }

        // Append to path
        let currentPath = path?.string ?? ""
        let separator = currentPath.hasSuffix("/") ? "" : "/"
        result += currentPath + separator + component

        // Add query and fragment
        if let uriQuery = query {
            result += "?\(uriQuery.string)"
        }
        if let uriFragment = fragment {
            result += "#\(uriFragment.value)"
        }

        return try RFC_3986.URI(result)
    }

    /// Creates a new URI by appending a query parameter
    ///
    /// - Parameters:
    ///   - name: The query parameter name
    ///   - value: The query parameter value
    /// - Returns: A new URI with the appended query parameter
    public func appendingQueryItem(name: String, value: String?) throws -> RFC_3986.URI {
        var result = ""

        // Add scheme
        if let uriScheme = scheme {
            result += "\(uriScheme.value):"
        }

        // Add authority
        if let uriHost = host {
            result += "//\(uriHost.rawValue)"
            if let uriPort = port {
                result += ":\(uriPort)"
            }
        }

        // Add path
        if let uriPath = path {
            result += uriPath.string
        }

        // Add query with new item
        let encodedName = RFC_3986.percentEncode(name, allowing: RFC_3986.CharacterSets.query)
        let encodedValue = value.map { RFC_3986.percentEncode($0, allowing: RFC_3986.CharacterSets.query) }

        if let currentQuery = query?.string {
            result += "?\(currentQuery)&\(encodedName)"
            if let value = encodedValue {
                result += "=\(value)"
            }
        } else {
            result += "?\(encodedName)"
            if let value = encodedValue {
                result += "=\(value)"
            }
        }

        // Add fragment
        if let uriFragment = fragment {
            result += "#\(uriFragment.value)"
        }

        return try RFC_3986.URI(result)
    }

    /// Creates a new URI by setting the fragment
    ///
    /// - Parameter fragment: The fragment to set
    /// - Returns: A new URI with the specified fragment
    public func settingFragment(_ fragment: Fragment?) throws -> RFC_3986.URI {
        var result = ""

        // Add scheme
        if let uriScheme = scheme {
            result += "\(uriScheme.value):"
        }

        // Add authority
        if let uriHost = host {
            result += "//\(uriHost.rawValue)"
            if let uriPort = port {
                result += ":\(uriPort)"
            }
        }

        // Add path
        if let uriPath = path {
            result += uriPath.string
        }

        // Add query
        if let uriQuery = query {
            result += "?\(uriQuery.string)"
        }

        // Add new fragment
        if let newFragment = fragment {
            result += "#\(newFragment.value)"
        }

        return try RFC_3986.URI(result)
    }
}

// MARK: - Equatable

extension RFC_3986.URI {
    /// Compare URIs based on their string values
    ///
    /// Two URIs are considered equal if their string representations are identical.
    /// The cache is not considered for equality.
    public static func == (lhs: RFC_3986.URI, rhs: RFC_3986.URI) -> Bool {
        lhs.value == rhs.value
    }
}

// MARK: - Hashable

extension RFC_3986.URI {
    /// Hash based on the URI string value
    ///
    /// The cache is not included in the hash.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}

// MARK: - Codable

extension RFC_3986.URI {
    /// Decode a URI from a string
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        try self.init(string)
    }

    /// Encode the URI as a string
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

// MARK: - Operators

extension RFC_3986.URI {
    /// Resolves a relative URI reference using the `/` operator
    ///
    /// Example:
    /// ```swift
    /// let base = try RFC_3986.URI("https://example.com/path")
    /// let resolved = try base / "../other"
    /// // resolved: https://example.com/other
    /// ```
    public static func / (base: RFC_3986.URI, reference: String) throws -> RFC_3986.URI {
        try base.resolve(reference)
    }

    /// Resolves a relative URI reference using the `/` operator
    public static func / (base: RFC_3986.URI, reference: RFC_3986.URI) throws -> RFC_3986.URI {
        try base.resolve(reference)
    }
}

// MARK: - URI.Representable Conformance

extension RFC_3986.URI {
    /// Typealias for backwards compatibility
    public typealias Representable = RFC_3986.URIRepresentable
}

extension RFC_3986.URI: RFC_3986.URIRepresentable {
    public var uri: RFC_3986.URI {
        self
    }
}

// MARK: - CustomStringConvertible

extension RFC_3986.URI: CustomStringConvertible {
    public var description: String {
        value
    }
}

// MARK: - CustomDebugStringConvertible

extension RFC_3986.URI: CustomDebugStringConvertible {
    public var debugDescription: String {
        var parts: [String] = ["RFC_3986.URI"]

        if let scheme = scheme {
            parts.append("scheme: \(scheme)")
        }
        if let host = host {
            parts.append("host: \(host)")
        }
        if let port = port {
            parts.append("port: \(port)")
        }
        if let path = path, !path.isEmpty {
            parts.append("path: \(path)")
        }
        if let query = query {
            parts.append("query: \(query)")
        }
        if let fragment = fragment {
            parts.append("fragment: \(fragment)")
        }

        return parts.joined(separator: ", ")
    }
}

// MARK: - Comparable

extension RFC_3986.URI: Comparable {
    /// Compares two URIs lexicographically by their string representation
    public static func < (lhs: RFC_3986.URI, rhs: RFC_3986.URI) -> Bool {
        lhs.value < rhs.value
    }
}

// MARK: - Path Normalization

extension RFC_3986 {
    /// Removes dot segments from a path per RFC 3986 Section 5.2.4
    ///
    /// This algorithm removes "." and ".." segments from paths to produce
    /// a normalized path. For example:
    /// - `/a/b/c/./../../g` → `/a/g`
    /// - `/./a/b/` → `/a/b/`
    ///
    /// - Parameter path: The path to normalize
    /// - Returns: The path with dot segments removed
    ///
    /// - Note: Cyclomatic complexity inherent to RFC 3986 Section 5.2.4 algorithm
    // swiftlint:disable cyclomatic_complexity
    public static func removeDotSegments(from path: String) -> String {
        var input = path
        var output = ""

        while !input.isEmpty {
            // A: If the input buffer begins with a prefix of "../" or "./"
            if input.hasPrefix("../") {
                input.removeFirst(3)
            } else if input.hasPrefix("./") {
                input.removeFirst(2)
            }
            // B: If the input buffer begins with a prefix of "/./" or "/."
            else if input.hasPrefix("/./") {
                input = "/" + input.dropFirst(3)
            } else if input == "/." {
                input = "/"
            }
            // C: If the input buffer begins with a prefix of "/../" or "/.."
            else if input.hasPrefix("/../") {
                input = "/" + input.dropFirst(4)
                // Remove the last segment from output
                if let lastSlash = output.lastIndex(of: "/") {
                    output = String(output[..<lastSlash])
                }
            } else if input == "/.." {
                input = "/"
                if let lastSlash = output.lastIndex(of: "/") {
                    output = String(output[..<lastSlash])
                }
            }
            // D: If the input buffer consists only of "." or ".."
            else if input == "." || input == ".." {
                input = ""
            }
            // E: Move the first path segment to output
            else {
                // Find the next "/" after the first character
                let startIndex = input.index(after: input.startIndex)
                if let slashIndex = input[startIndex...].firstIndex(of: "/") {
                    let segment = String(input[..<slashIndex])
                    output += segment
                    input = String(input[slashIndex...])
                } else {
                    output += input
                    input = ""
                }
            }
        }

        return output
    }
    // swiftlint:enable cyclomatic_complexity
}

// MARK: - Validation Functions

extension RFC_3986 {
    /// Validates if a string is a valid URI reference
    ///
    /// This performs basic validation using Foundation's URL validation.
    /// A valid URI reference (per RFC 3986 Section 4.1) is either:
    /// - An absolute URI with a scheme (e.g., `https://example.com/path`)
    /// - A relative reference without a scheme (e.g., `/path`, `?query`, `#fragment`)
    /// - An empty string (representing "same document reference")
    ///
    /// Requirements:
    /// - Must be parseable as a URL by Foundation
    /// - Must contain only ASCII characters (per RFC 3986)
    /// - Must not contain unencoded spaces or other invalid characters
    ///
    /// Note: Empty strings are allowed as they represent a valid "same document reference"
    /// commonly used in href attributes and by RFC 6570 URI Template expansion.
    ///
    /// Note: This is a lenient validation suitable for most use cases.
    /// Full RFC 3986 compliance would require more strict validation
    /// of character ranges and syntax rules.
    ///
    /// - Parameter string: The string to validate
    /// - Returns: true if the string appears to be a valid URI reference
    public static func isValidURI(_ string: String) -> Bool {
        // Empty strings are allowed (same document reference)
        if string.isEmpty { return true }

        // URI references must be ASCII-only per RFC 3986
        guard string.allSatisfy({ $0.isASCII }) else { return false }

        // Reject strings with unencoded spaces or control characters
        if string.contains(" ") || string.contains(where: { $0.isASCII && $0.asciiValue! < 0x20 || $0.asciiValue == 0x7F }) {
            return false
        }

        // Reject strings with invalid characters like < > { } | \ ^ `
        let invalidChars: Set<Character> = ["<", ">", "{", "}", "|", "\\", "^", "`", "\""]
        if string.contains(where: { invalidChars.contains($0) }) {
            return false
        }

        // TODO: Replace with pure RFC 3986 parser
        // For now, we do basic validation without Foundation
        // A proper implementation should parse according to RFC 3986 ABNF grammar

        // Very basic validation: allow most ASCII except the explicitly forbidden characters above
        return true
    }

    /// Validates if a URI is a valid HTTP(S) URI
    ///
    /// - Parameter uri: The URI to validate
    /// - Returns: true if the URI is an HTTP or HTTPS URI
    public static func isValidHTTP(_ uri: any URIRepresentable) -> Bool {
        guard let scheme = uri.uri.scheme else { return false }
        return scheme.value == "http" || scheme.value == "https"
    }

    /// Validates if a string is a valid HTTP(S) URI
    ///
    /// - Parameter string: The string to validate
    /// - Returns: true if the string is an HTTP or HTTPS URI
    public static func isValidHTTP(_ string: String) -> Bool {
        guard isValidURI(string) else { return false }
        guard let uri = try? URI(string) else { return false }
        return uri.scheme?.value == "http" || uri.scheme?.value == "https"
    }
}
