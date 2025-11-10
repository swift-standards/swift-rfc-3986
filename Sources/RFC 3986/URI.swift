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
            return "Invalid URI: '\(value)'. URIs must have a scheme and contain only ASCII characters."
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
            return "Use percent-encoding for non-ASCII characters, or consider using RFC 3987 (IRI) instead"
        case .invalidURI:
            return "Ensure the URI includes a scheme (e.g., https://) and follows RFC 3986 syntax"
        case .invalidComponent:
            return "Check that the component follows RFC 3986 requirements for its type"
        case .conversionFailed:
            return "Verify the input is well-formed and try again"
        }
    }
}

extension RFC_3986 {
    /// A Uniform Resource Identifier (URI) as defined in RFC 3986
    ///
    /// URIs provide a simple and extensible means for identifying a resource.
    /// They use a restricted set of ASCII characters to ensure maximum compatibility
    /// across different systems and protocols.
    ///
    /// RFC 3986 defines a generic syntax consisting of a hierarchical sequence of
    /// five components: scheme, authority, path, query, and fragment.
    ///
    /// For protocol-oriented usage with types like `URL`, see the nested `URI.Representable` type.
    public struct URI: Hashable, Sendable, Codable {
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
        public protocol Representable {
            /// The URI as a string
            var uriString: String { get }
        }

        /// The URI string
        public let value: String

        /// Creates a URI from a string with validation
        ///
        /// - Parameter value: The URI string
        /// - Throws: RFC_3986.Error if the string is not a valid URI
        public init(_ value: String) throws {
            guard RFC_3986.isValidURI(value) else {
                throw RFC_3986.Error.invalidURI(value)
            }
            self.value = value
        }

        /// Creates a URI from a string without validation (for internal use)
        ///
        /// - Parameter value: The URI string
        internal init(unchecked value: String) {
            self.value = value
        }

        /// Returns a normalized version of this URI
        ///
        /// Per RFC 3986 Section 6, normalization includes:
        /// - Case normalization of scheme and host (Section 6.2.2.1)
        /// - Percent-encoding normalization (Section 6.2.2.2)
        /// - Path segment normalization (Section 6.2.2.3)
        /// - Removal of default ports
        ///
        /// - Returns: A normalized URI
        public func normalized() -> URI {
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

            return URI(unchecked: normalizedURL.absoluteString)
        }

        /// Indicates whether this URI is a relative reference
        ///
        /// Per RFC 3986 Section 4.2, a relative reference does not begin with a scheme.
        /// Examples: `//example.com/path`, `/path`, `path`, `?query`, `#fragment`
        ///
        /// - Returns: true if this is a relative reference, false if absolute
        public var isRelative: Bool {
            scheme == nil
        }

        /// Resolves a relative URI reference against this URI as a base
        ///
        /// Per RFC 3986 Section 5, this implements the URI resolution algorithm
        /// to convert a relative reference into an absolute URI.
        ///
        /// - Parameter reference: The URI reference to resolve (may be relative or absolute)
        /// - Returns: The resolved absolute URI
        /// - Throws: RFC_3986.Error if resolution fails
        public func resolve(_ reference: URI) throws -> URI {
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
        public func resolve(_ reference: String) throws -> URI {
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

            return URI(unchecked: result)
        }

        /// The components of this URI
        ///
        /// Returns the parsed URI components including scheme, authority, path, query, and fragment.
        ///
        /// - Returns: URLComponents if the URI can be parsed, nil otherwise
        public var components: URLComponents? {
            guard let url = URL(string: value) else {
                return nil
            }
            return URLComponents(url: url, resolvingAgainstBaseURL: false)
        }

        /// The scheme component of this URI
        ///
        /// Per RFC 3986 Section 3.1, the scheme is the first component of a URI
        /// and is followed by a colon. Scheme names consist of a sequence of characters
        /// beginning with a letter and followed by any combination of letters, digits,
        /// plus (+), period (.), or hyphen (-).
        public var scheme: String? {
            components?.scheme
        }

        /// The host component of this URI
        ///
        /// Per RFC 3986 Section 3.2.2, the host is identified by an IP literal,
        /// IPv4 address, or registered name.
        public var host: String? {
            components?.host
        }

        /// The port component of this URI
        ///
        /// Per RFC 3986 Section 3.2.3, the port is designated by an optional decimal
        /// port number following the host and delimited from it by a colon.
        public var port: Int? {
            components?.port
        }

        /// The path component of this URI
        ///
        /// Per RFC 3986 Section 3.3, the path contains data that identifies a resource
        /// within the scope of the URI's scheme and authority.
        public var path: String? {
            components?.path
        }

        /// The query component of this URI
        ///
        /// Per RFC 3986 Section 3.4, the query contains non-hierarchical data that
        /// identifies a resource in conjunction with the scheme and authority.
        public var query: String? {
            components?.query
        }

        /// The fragment component of this URI
        ///
        /// Per RFC 3986 Section 3.5, the fragment allows indirect identification
        /// of a secondary resource by reference to a primary resource.
        public var fragment: String? {
            components?.fragment
        }

        // MARK: - Convenience Properties

        /// Returns `true` if this URI uses a secure scheme (https, wss, etc.)
        public var isSecure: Bool {
            guard let uriScheme = scheme?.lowercased() else { return false }
            return ["https", "wss", "ftps"].contains(uriScheme)
        }

        /// Returns `true` if this URI is an HTTP or HTTPS URI
        public var isHTTP: Bool {
            guard let uriScheme = scheme?.lowercased() else { return false }
            return uriScheme == "http" || uriScheme == "https"
        }

        /// Returns the base URI (scheme + authority) without path, query, or fragment
        ///
        /// Example: `https://example.com:8080/path?query#fragment` → `https://example.com:8080`
        public var base: URI? {
            guard let urlComponents = components,
                let uriScheme = urlComponents.scheme,
                let uriHost = urlComponents.host
            else { return nil }

            var baseString = "\(uriScheme)://\(uriHost)"
            if let uriPort = urlComponents.port {
                baseString += ":\(uriPort)"
            }
            return URI(unchecked: baseString)
        }

        /// Returns the path and query components combined
        ///
        /// Example: `/path?key=value`
        public var pathAndQuery: String? {
            guard let uriPath = path else { return nil }
            if let uriQuery = query {
                return "\(uriPath)?\(uriQuery)"
            }
            return uriPath
        }

        // MARK: - Convenience Methods

        /// Creates a new URI by appending a path component
        ///
        /// - Parameter component: The path component to append
        /// - Returns: A new URI with the appended path component
        public func appendingPathComponent(_ component: String) throws -> URI {
            guard var urlComponents = components else {
                throw RFC_3986.Error.invalidURI(value)
            }

            let currentPath = urlComponents.path
            let separator = currentPath.hasSuffix("/") ? "" : "/"
            urlComponents.path = currentPath + separator + component

            guard let url = urlComponents.url else {
                throw RFC_3986.Error.conversionFailed("Could not append path component")
            }

            return URI(unchecked: url.absoluteString)
        }

        /// Creates a new URI by appending a query parameter
        ///
        /// - Parameters:
        ///   - name: The query parameter name
        ///   - value: The query parameter value
        /// - Returns: A new URI with the appended query parameter
        public func appendingQueryItem(name: String, value: String?) throws -> URI {
            guard var urlComponents = components else {
                throw RFC_3986.Error.invalidURI(self.value)
            }

            var queryItems = urlComponents.queryItems ?? []
            queryItems.append(URLQueryItem(name: name, value: value))
            urlComponents.queryItems = queryItems

            guard let url = urlComponents.url else {
                throw RFC_3986.Error.conversionFailed("Could not append query item")
            }

            return URI(unchecked: url.absoluteString)
        }

        /// Creates a new URI by setting the fragment
        ///
        /// - Parameter fragment: The fragment to set
        /// - Returns: A new URI with the specified fragment
        public func settingFragment(_ fragment: String?) throws -> URI {
            guard var urlComponents = components else {
                throw RFC_3986.Error.invalidURI(value)
            }

            urlComponents.fragment = fragment

            guard let url = urlComponents.url else {
                throw RFC_3986.Error.conversionFailed("Could not set fragment")
            }

            return URI(unchecked: url.absoluteString)
        }

        // MARK: - Operators

        /// Resolves a relative URI reference using the `/` operator
        ///
        /// Example:
        /// ```swift
        /// let base = try RFC_3986.URI("https://example.com/path")
        /// let resolved = try base / "../other"
        /// // resolved: https://example.com/other
        /// ```
        public static func / (base: URI, reference: String) throws -> URI {
            try base.resolve(reference)
        }

        /// Resolves a relative URI reference using the `/` operator
        public static func / (base: URI, reference: URI) throws -> URI {
            try base.resolve(reference)
        }
    }

    // MARK: - Path Normalization

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

    // MARK: - Validation Functions

    /// Validates if a string is a valid URI
    ///
    /// This performs basic validation using Foundation's URL validation.
    /// A valid URI should:
    /// - Be a valid URL according to Foundation
    /// - Have a scheme (e.g., http, https, urn, mailto, ftp)
    /// - Contain only ASCII characters (per RFC 3986)
    ///
    /// Note: This is a lenient validation suitable for most use cases.
    /// Full RFC 3986 compliance would require more strict validation
    /// of character ranges and syntax rules.
    ///
    /// - Parameter string: The string to validate
    /// - Returns: true if the string appears to be a valid URI
    public static func isValidURI(_ string: String) -> Bool {
        // Empty strings are not valid URIs
        guard !string.isEmpty else { return false }

        // URIs must be ASCII-only per RFC 3986
        // Foundation's URL accepts non-ASCII characters, so we need to check explicitly
        guard string.allSatisfy({ $0.isASCII }) else { return false }

        // Try to create a URL from the string
        guard let url = URL(string: string) else { return false }

        // URI must have a scheme per RFC 3986
        guard url.scheme != nil else { return false }

        return true
    }

    /// Validates if a URI is a valid HTTP(S) URI
    ///
    /// - Parameter uri: The URI to validate
    /// - Returns: true if the URI is an HTTP or HTTPS URI
    public static func isValidHTTP(_ uri: any URI.Representable) -> Bool {
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

// MARK: - URI.Representable Conformance

extension RFC_3986.URI: RFC_3986.URI.Representable {
    public var uriString: String {
        value
    }
}

// MARK: - Foundation URL Conformance

extension URL: RFC_3986.URI.Representable {
    /// The URL as a URI string
    ///
    /// Foundation's URL type uses percent-encoding for non-ASCII characters,
    /// making it compatible with URIs as defined in RFC 3986.
    public var uriString: String {
        absoluteString
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

// MARK: - CustomStringConvertible & CustomDebugStringConvertible

extension RFC_3986.URI: CustomStringConvertible {
    public var description: String {
        value
    }
}

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
