import Foundation

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

extension RFC_3986.Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURI(let value):
            return
                "Invalid URI: '\(value)'. URIs must have a scheme and contain only ASCII characters."
        case .invalidComponent(let component):
            return "Invalid URI component: '\(component)'"
        case .conversionFailed(let reason):
            return "URI conversion failed: \(reason)"
        }
    }

    public var failureReason: String? {
        switch self {
        case .invalidURI:
            return "The string does not conform to RFC 3986 URI syntax"
        case .invalidComponent:
            return "The component contains invalid characters or structure"
        case .conversionFailed:
            return "The operation could not be completed"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidURI(let value) where value.contains(where: { !$0.isASCII }):
            return
                "Use percent-encoding for non-ASCII characters, or consider using RFC 3987 (IRI) instead"
        case .invalidURI:
            return "Ensure the URI includes a scheme (e.g., https://) and follows RFC 3986 syntax"
        case .invalidComponent:
            return "Check that the component follows RFC 3986 requirements for its type"
        case .conversionFailed:
            return "Verify the input is well-formed and try again"
        }
    }
}

// MARK: - URI.Representable Protocol

extension RFC_3986 {
    /// Protocol for types that can represent URIs
    ///
    /// Types conforming to this protocol can be used interchangeably wherever a URI
    /// is expected, including Foundation's `URL` type.
    ///
    /// Example:
    /// ```swift
    /// func process(uri: any RFC_3986.URI.Representable) {
    ///     print(uri.uriString)
    /// }
    ///
    /// let url = URL(string: "https://example.com")!
    /// process(uri: url)  // Works!
    /// ```
    public protocol URIRepresentable {
        /// The URI representation
        var uri: RFC_3986.URI { get }
    }
}

extension RFC_3986.URIRepresentable {
    /// The URI as a string (convenience)
    public var uriString: String {
        uri.value
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
        let urlComponents: URLComponents?

        // Lazy cached components - parsed once on first access
        lazy var scheme: Scheme? = {
            urlComponents?.scheme.flatMap { try? Scheme($0) }
        }()

        lazy var host: Host? = {
            urlComponents?.host.flatMap { try? Host($0) }
        }()

        lazy var port: Port? = {
            urlComponents?.port.flatMap { Port(UInt16($0)) }
        }()

        lazy var path: Path? = {
            guard let pathString = urlComponents?.path else { return nil }
            return try? Path(pathString)
        }()

        lazy var query: Query? = {
            urlComponents?.query.flatMap { try? Query($0) }
        }()

        lazy var fragment: Fragment? = {
            urlComponents?.fragment.flatMap { try? Fragment($0) }
        }()

        init(value: String) {
            self.value = value

            // Parse URLComponents once at initialization
            if let url = URL(string: value) {
                self.urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
            } else {
                self.urlComponents = nil
            }
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
    /// been performed (e.g., after URLComponents validation, or for static constants).
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
    /// The components of this URI
    ///
    /// Returns the parsed URI components including scheme, authority, path, query, and fragment.
    ///
    /// - Returns: URLComponents if the URI can be parsed, nil otherwise
    public var components: URLComponents? {
        cache.urlComponents
    }

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
        guard let urlComponents = cache.urlComponents else { return nil }

        // URLComponents stores user and password separately
        return urlComponents.user
            .map { user in
                urlComponents.password
                    .map { "\(user):\($0)" }
                    ?? user
            }
            .flatMap { try? Userinfo.init($0) }
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
        guard let url = URL(string: value) else {
            return self
        }

        // Foundation's URL automatically performs many normalizations
        // when created, so we can use its normalized representation
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return self
        }

        // Normalize scheme and host to lowercase (Section 6.2.2.1)
        if let scheme = components.scheme {
            components.scheme = scheme.lowercased()
        }
        if let host = components.host {
            components.host = host.lowercased()
        }

        // Remove default ports
        if let scheme = components.scheme, let port = components.port {
            let defaultPort =
                (scheme == "http" && port == 80) || (scheme == "https" && port == 443)
                || (scheme == "ftp" && port == 21)
            if defaultPort {
                components.port = nil
            }
        }

        // Normalize path by removing dot segments (Section 6.2.2.3)
        let path = components.path
        if !path.isEmpty {
            components.path = RFC_3986.removeDotSegments(from: path)
        }

        guard let normalizedURL = components.url else {
            return self
        }

        return RFC_3986.URI(unchecked: normalizedURL.absoluteString)
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
        guard components != nil else {
            throw RFC_3986.Error.invalidURI(value)
        }

        guard let url = URL(string: value) else {
            throw RFC_3986.Error.invalidURI(value)
        }

        // Try to create a URL from the reference, resolving against base
        guard let resolvedURL = URL(string: reference, relativeTo: url) else {
            throw RFC_3986.Error.invalidURI(reference)
        }

        // Get the absolute string
        guard let absoluteString = resolvedURL.absoluteString.split(separator: "#").first else {
            throw RFC_3986.Error.invalidURI(reference)
        }

        var result = String(absoluteString)

        // If the reference had a fragment, preserve it
        if let fragmentIndex = reference.firstIndex(of: "#") {
            result += String(reference[fragmentIndex...])
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
        guard var urlComponents = components else {
            throw RFC_3986.Error.invalidURI(value)
        }

        let currentPath = urlComponents.path
        let separator = currentPath.hasSuffix("/") ? "" : "/"
        urlComponents.path = currentPath + separator + component

        guard let url = urlComponents.url else {
            throw RFC_3986.Error.conversionFailed("Could not append path component")
        }

        return RFC_3986.URI(unchecked: url.absoluteString)
    }

    /// Creates a new URI by appending a query parameter
    ///
    /// - Parameters:
    ///   - name: The query parameter name
    ///   - value: The query parameter value
    /// - Returns: A new URI with the appended query parameter
    public func appendingQueryItem(name: String, value: String?) throws -> RFC_3986.URI {
        guard var urlComponents = components else {
            throw RFC_3986.Error.invalidURI(self.value)
        }

        var queryItems = urlComponents.queryItems ?? []
        queryItems.append(URLQueryItem(name: name, value: value))
        urlComponents.queryItems = queryItems

        guard let url = urlComponents.url else {
            throw RFC_3986.Error.conversionFailed("Could not append query item")
        }

        return RFC_3986.URI(unchecked: url.absoluteString)
    }

    /// Creates a new URI by setting the fragment
    ///
    /// - Parameter fragment: The fragment to set
    /// - Returns: A new URI with the specified fragment
    public func settingFragment(_ fragment: Fragment?) throws -> RFC_3986.URI {
        guard var urlComponents = components else {
            throw RFC_3986.Error.invalidURI(value)
        }

        urlComponents.fragment = fragment?.value

        guard let url = urlComponents.url else {
            throw RFC_3986.Error.conversionFailed("Could not set fragment")
        }

        return RFC_3986.URI(unchecked: url.absoluteString)
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

// MARK: - Foundation URL Conformance

extension URL: RFC_3986.URIRepresentable {
    /// The URL as a URI
    ///
    /// Foundation's URL type uses percent-encoding for non-ASCII characters,
    /// making it compatible with URIs as defined in RFC 3986.
    public var uri: RFC_3986.URI {
        RFC_3986.URI(unchecked: absoluteString)
    }
}

// MARK: - ExpressibleByStringLiteral

extension RFC_3986.URI: ExpressibleByStringLiteral {
    /// Creates a URI from a string literal without validation
    ///
    /// Example:
    /// ```swift
    /// let uri: RFC_3986.URI = "https://example.com/path"
    /// ```
    ///
    /// Note: This does not perform validation. For validated creation,
    /// use `try RFC_3986.URI("string")`.
    @_disfavoredOverload
    public init(stringLiteral value: String) {
        self.init(unchecked: value)
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
        // Foundation's URL accepts non-ASCII characters, so we need to check explicitly
        guard string.allSatisfy({ $0.isASCII }) else { return false }

        // Reject strings with unencoded spaces or control characters
        if string.contains(" ") || string.rangeOfCharacter(from: .controlCharacters) != nil {
            return false
        }

        // Reject strings with invalid characters like < > { } | \ ^ `
        let invalidChars = CharacterSet(charactersIn: "<>{}|\\^`\"")
        if string.rangeOfCharacter(from: invalidChars) != nil {
            return false
        }

        // Try to create a URL from the string (Foundation URL handles both absolute and relative)
        // For relative references, we use a dummy base to validate parsing
        if URL(string: string) != nil {
            return true
        }

        // Try parsing as relative reference with a base URL
        if let _ = URL(string: string, relativeTo: URL(string: "http://example.com")) {
            return true
        }

        return false
    }

    /// Validates if a URI is a valid HTTP(S) URI
    ///
    /// - Parameter uri: The URI to validate
    /// - Returns: true if the URI is an HTTP or HTTPS URI
    public static func isValidHTTP(_ uri: any URIRepresentable) -> Bool {
        guard let url = URL(string: uri.uriString) else { return false }
        return url.scheme == "http" || url.scheme == "https"
    }

    /// Validates if a string is a valid HTTP(S) URI
    ///
    /// - Parameter string: The string to validate
    /// - Returns: true if the string is an HTTP or HTTPS URI
    public static func isValidHTTP(_ string: String) -> Bool {
        guard isValidURI(string) else { return false }
        guard let url = URL(string: string) else { return false }
        return url.scheme == "http" || url.scheme == "https"
    }
}
