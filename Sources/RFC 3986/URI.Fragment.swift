import Foundation

// MARK: - URI Fragment

extension RFC_3986.URI {
    /// URI fragment component per RFC 3986 Section 3.5
    ///
    /// The fragment identifier component allows indirect identification of a secondary resource
    /// by reference to a primary resource and additional identifying information.
    ///
    /// Fragments are client-side only and are not sent to the server in HTTP requests.
    /// They are separated from the rest of the URI before dereferencing.
    ///
    /// ## Example
    /// ```swift
    /// // Create from string
    /// let fragment = try RFC_3986.URI.Fragment("section-1")
    /// print(fragment.value) // "section-1"
    ///
    /// // Use in URI
    /// let uri = try RFC_3986.URI("https://example.com/page#section-1")
    /// print(uri.fragment?.value) // "section-1"
    ///
    /// // Common patterns
    /// let heading = try RFC_3986.URI.Fragment("heading-intro")
    /// let anchor = try RFC_3986.URI.Fragment("top")
    /// ```
    ///
    /// ## RFC 3986 Reference
    /// ```
    /// fragment = *( pchar / "/" / "?" )
    /// ```
    ///
    /// Per RFC 3986 Section 3.5:
    /// > The fragment identifier component allows indirect identification of a
    /// > secondary resource by reference to a primary resource and additional
    /// > identifying information. [...] The semantics of a fragment identifier
    /// > are defined by the set of representations that might result from a
    /// > retrieval action on the primary resource.
    public struct Fragment: Sendable {
        /// The fragment value
        public let value: String

        /// Creates a fragment from a string with validation
        ///
        /// - Parameter value: The fragment string (without leading "#")
        /// - Throws: `RFC_3986.Error.invalidComponent` if the fragment contains invalid characters
        ///
        /// Example:
        /// ```swift
        /// let fragment = try RFC_3986.URI.Fragment("section-1")
        /// let heading = try RFC_3986.URI.Fragment("introduction")
        /// ```
        public init(_ value: String) throws {
            // Basic validation - check for obviously invalid characters
            // Full validation would check against: *( pchar / "/" / "?" )
            if value.contains(where: { $0.isNewline }) {
                throw RFC_3986.Error.invalidComponent("Fragment contains newline")
            }

            // Fragments cannot contain "#" (that would start a new fragment)
            if value.contains("#") {
                throw RFC_3986.Error.invalidComponent("Fragment cannot contain '#' character")
            }

            self.value = value
        }

        /// Creates a fragment without validation
        ///
        /// This is an internal optimization for cases where validation has already
        /// been performed or for static constants.
        ///
        /// - Parameter value: The fragment string (must be valid, not validated)
        /// - Warning: This skips validation. For public use, use `try!` with
        ///   the throwing initializer to make the risk explicit.
        internal init(unchecked value: String) {
            self.value = value
        }

        /// The string representation of the fragment
        ///
        /// Returns the fragment value (without leading "#").
        public var string: String {
            value
        }

        /// Returns true if the fragment is empty
        public var isEmpty: Bool {
            value.isEmpty
        }
    }
}

// MARK: - Equatable

extension RFC_3986.URI.Fragment: Equatable {
    public static func == (lhs: RFC_3986.URI.Fragment, rhs: RFC_3986.URI.Fragment) -> Bool {
        lhs.value == rhs.value
    }
}

// MARK: - Hashable

extension RFC_3986.URI.Fragment: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}

// MARK: - CustomStringConvertible

extension RFC_3986.URI.Fragment: CustomStringConvertible {
    public var description: String {
        value
    }
}

// MARK: - Codable

extension RFC_3986.URI.Fragment: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        try self.init(string)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
