// Set<Character>.swift
// swift-rfc-3986
//
// Convenience extensions for RFC 3986 character sets

extension Set<Character> {
    /// Namespace for URI character sets per RFC 3986
    ///
    /// Provides convenient access to RFC 3986 character sets via `.uri` namespace:
    /// ```swift
    /// let allowed: Set<Character> = .uri.unreserved
    /// let query: Set<Character> = .uri.query
    /// let path: Set<Character> = .uri.pathSegment
    /// ```
    public enum URI {
        /// Unreserved characters per RFC 3986 Section 2.3
        public static var unreserved: Set<Character> {
            RFC_3986.CharacterSet.unreserved.characters
        }

        /// Reserved characters per RFC 3986 Section 2.2
        public static var reserved: Set<Character> {
            RFC_3986.CharacterSet.reserved.characters
        }

        /// General delimiters per RFC 3986 Section 2.2
        public static var genDelims: Set<Character> {
            RFC_3986.CharacterSet.genDelims.characters
        }

        /// Sub-delimiters per RFC 3986 Section 2.2
        public static var subDelims: Set<Character> {
            RFC_3986.CharacterSet.subDelims.characters
        }

        /// Characters allowed in scheme per RFC 3986 Section 3.1
        public static var scheme: Set<Character> {
            RFC_3986.CharacterSet.scheme.characters
        }

        /// Characters allowed in userinfo per RFC 3986 Section 3.2.1
        public static var userinfo: Set<Character> {
            RFC_3986.CharacterSet.userinfo.characters
        }

        /// Characters allowed in host per RFC 3986 Section 3.2.2
        public static var host: Set<Character> {
            RFC_3986.CharacterSet.host.characters
        }

        /// Characters allowed in path segments per RFC 3986 Section 3.3
        public static var pathSegment: Set<Character> {
            RFC_3986.CharacterSet.pathSegment.characters
        }

        /// Characters allowed in query per RFC 3986 Section 3.4
        public static var query: Set<Character> {
            RFC_3986.CharacterSet.query.characters
        }

        /// Characters allowed in fragment per RFC 3986 Section 3.5
        public static var fragment: Set<Character> {
            RFC_3986.CharacterSet.fragment.characters
        }
    }
}

extension Set<Character> {
    /// Convenient access to RFC 3986 character sets
    public static var uri: URI.Type {
        URI.self
    }
}

extension Set<Character> {
    /// Creates a `Set<Character>` from an RFC 3986 character set
    public init(_ characterSet: RFC_3986.CharacterSet) {
        self = characterSet.characters
    }
}
