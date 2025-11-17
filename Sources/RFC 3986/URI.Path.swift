import Foundation

// MARK: - URI Path

extension RFC_3986.URI {
    /// URI path component per RFC 3986 Section 3.3
    ///
    /// The path component contains data, usually organized in hierarchical form,
    /// that identifies a resource within the scope of the URI's scheme and authority.
    ///
    /// ## Example
    /// ```swift
    /// // Absolute path
    /// let absolute = try RFC_3986.URI.Path(
    ///     segments: ["users", "123", "profile"],
    ///     isAbsolute: true
    /// )
    /// print(absolute.string) // "/users/123/profile"
    ///
    /// // Relative path
    /// let relative = try RFC_3986.URI.Path(
    ///     segments: ["docs", "readme.md"],
    ///     isAbsolute: false
    /// )
    /// print(relative.string) // "docs/readme.md"
    ///
    /// // Parse from string
    /// let parsed = try RFC_3986.URI.Path("/api/v1/users")
    /// print(parsed.segments) // ["api", "v1", "users"]
    /// ```
    ///
    /// ## RFC 3986 Reference
    /// ```
    /// path = path-abempty    ; begins with "/" or is empty
    ///      / path-absolute   ; begins with "/" but not "//"
    ///      / path-noscheme   ; begins with a non-colon segment
    ///      / path-rootless   ; begins with a segment
    ///      / path-empty      ; zero characters
    /// ```
    public struct Path: Sendable, Equatable, Hashable {
        /// The path segments (without separators)
        ///
        /// For example, "/users/123" has segments ["users", "123"]
        public let segments: [String]

        /// Whether this is an absolute path (starts with /)
        ///
        /// Absolute paths start with "/" while relative paths do not.
        public let isAbsolute: Bool

        /// Creates a path from segments
        ///
        /// - Parameters:
        ///   - segments: The path segments (should not contain "/" or be percent-encoded)
        ///   - isAbsolute: Whether this is an absolute path (defaults to true)
        /// - Throws: `RFC_3986.Error.invalidComponent` if segments contain invalid characters
        public init(segments: [String], isAbsolute: Bool = true) throws {
            // Validate segments don't contain path separators
            for segment in segments {
                if segment.contains("/") {
                    throw RFC_3986.Error.invalidComponent(
                        "Path segment cannot contain '/': \(segment)"
                    )
                }
                // Check for invalid characters (very basic validation)
                // Full validation would check pchar production from RFC 3986
                if segment.contains(where: { $0.isNewline || $0.isWhitespace }) {
                    throw RFC_3986.Error.invalidComponent(
                        "Path segment contains invalid whitespace: \(segment)"
                    )
                }
            }

            self.segments = segments
            self.isAbsolute = isAbsolute
        }

        /// Creates a path without validation
        ///
        /// This is an internal optimization for static constants and validated values.
        ///
        /// - Parameters:
        ///   - segments: The path segments (must be valid, not validated)
        ///   - isAbsolute: Whether this is an absolute path
        /// - Warning: This skips validation. For public use, use `try!` with
        ///   the throwing initializer to make the risk explicit.
        internal init(unchecked segments: [String], isAbsolute: Bool = true) {
            self.segments = segments
            self.isAbsolute = isAbsolute
        }

        /// Creates a path from a string
        ///
        /// - Parameter string: The path string (e.g., "/users/123" or "docs/file.txt")
        /// - Throws: `RFC_3986.Error.invalidComponent` if the path is invalid
        public init(_ string: String) throws {
            if string.isEmpty {
                self.init(unchecked: [], isAbsolute: false)
                return
            }

            let isAbsolute = string.hasPrefix("/")
            let pathString = isAbsolute ? String(string.dropFirst()) : string

            if pathString.isEmpty {
                // Path is just "/"
                self.init(unchecked: [], isAbsolute: true)
                return
            }

            let segments = pathString.split(separator: "/", omittingEmptySubsequences: false)
                .map(String.init)

            try self.init(segments: segments, isAbsolute: isAbsolute)
        }

        /// The string representation of the path
        ///
        /// Returns the path in the form "/segment1/segment2" for absolute paths
        /// or "segment1/segment2" for relative paths.
        public var string: String {
            if segments.isEmpty {
                return isAbsolute ? "/" : ""
            }

            let joined = segments.joined(separator: "/")
            return isAbsolute ? "/\(joined)" : joined
        }

        /// Returns true if this path is empty (no segments)
        public var isEmpty: Bool {
            segments.isEmpty
        }

        /// The number of path segments
        public var count: Int {
            segments.count
        }

        /// Appends a path segment
        ///
        /// - Parameter segment: The segment to append
        /// - Returns: A new path with the segment appended
        /// - Throws: `RFC_3986.Error.invalidComponent` if the segment is invalid
        public func appending(_ segment: String) throws -> Path {
            var newSegments = segments
            newSegments.append(segment)
            return try Path(segments: newSegments, isAbsolute: isAbsolute)
        }

        /// Appends multiple path segments
        ///
        /// - Parameter segments: The segments to append
        /// - Returns: A new path with the segments appended
        /// - Throws: `RFC_3986.Error.invalidComponent` if any segment is invalid
        public func appending(contentsOf segments: [String]) throws -> Path {
            var newSegments = self.segments
            newSegments.append(contentsOf: segments)
            return try Path(segments: newSegments, isAbsolute: isAbsolute)
        }

        /// Returns a new path with the last segment removed
        ///
        /// - Returns: A path with the last segment removed, or self if empty
        public func deletingLastSegment() -> Path {
            guard !segments.isEmpty else { return self }
            var newSegments = segments
            newSegments.removeLast()
            return Path(unchecked: newSegments, isAbsolute: isAbsolute)
        }

        /// The last segment of the path, if any
        public var lastSegment: String? {
            segments.last
        }

        /// The first segment of the path, if any
        public var firstSegment: String? {
            segments.first
        }
    }
}

// MARK: - Collection

extension RFC_3986.URI.Path: Collection {
    public typealias Index = Array<String>.Index
    public typealias Element = String

    public var startIndex: Index {
        segments.startIndex
    }

    public var endIndex: Index {
        segments.endIndex
    }

    public subscript(position: Index) -> String {
        segments[position]
    }

    public func index(after i: Index) -> Index {
        segments.index(after: i)
    }
}

// MARK: - ExpressibleByArrayLiteral

extension RFC_3986.URI.Path: ExpressibleByArrayLiteral {
    /// Creates a path from an array literal of segments
    ///
    /// Example:
    /// ```swift
    /// let path: RFC_3986.URI.Path = ["users", "123", "profile"]
    /// ```
    ///
    /// - Note: Creates an absolute path by default. Use init(segments:isAbsolute:) for relative paths.
    public init(arrayLiteral elements: String...) {
        self.init(unchecked: elements, isAbsolute: true)
    }
}

// MARK: - CustomStringConvertible

extension RFC_3986.URI.Path: CustomStringConvertible {
    public var description: String {
        string
    }
}

// MARK: - Codable

extension RFC_3986.URI.Path: Codable {
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
