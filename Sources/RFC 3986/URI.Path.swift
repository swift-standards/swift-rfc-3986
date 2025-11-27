public import INCITS_4_1986

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

        /// Creates a path WITHOUT validation
        ///
        /// **Warning**: Bypasses RFC 3986 validation.
        /// Only use with compile-time constants or pre-validated values.
        ///
        /// - Parameters:
        ///   - unchecked: Void parameter to prevent accidental use
        ///   - segments: The path segments (unchecked)
        ///   - isAbsolute: Whether this is an absolute path
        init(
            __unchecked _: Void,
            segments: [String],
            isAbsolute: Bool
        ) {
            self.segments = segments
            self.isAbsolute = isAbsolute
        }
    }
}

// MARK: - Serializable

extension RFC_3986.URI.Path: UInt8.ASCII.Serializable {
    public static let serialize: @Sendable (Self) -> [UInt8] = [UInt8].init

    /// Parses path from ASCII bytes (CANONICAL PRIMITIVE)
    ///
    /// This is the primitive parser that works at the byte level.
    /// RFC 3986 paths follow one of: path-abempty / path-absolute / path-noscheme / path-rootless / path-empty
    ///
    /// ## Category Theory
    ///
    /// This is the fundamental parsing transformation:
    /// - **Domain**: [UInt8] (ASCII bytes)
    /// - **Codomain**: RFC_3986.URI.Path (structured data)
    ///
    /// ## RFC 3986 Section 3.3
    ///
    /// ```
    /// path = path-abempty / path-absolute / path-noscheme / path-rootless / path-empty
    /// segment = *pchar
    /// pchar = unreserved / pct-encoded / sub-delims / ":" / "@"
    /// ```
    ///
    /// - Parameter bytes: The ASCII byte representation of the path
    /// - Throws: `RFC_3986.URI.Path.Error` if the bytes are malformed
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void) throws(Error)
    where Bytes.Element == UInt8 {
        // Empty path
        guard !bytes.isEmpty else {
            self.init(__unchecked: (), segments: [], isAbsolute: false)
            return
        }

        let isAbsolute = bytes.first == 0x2F  // '/'

        // Path is just "/"
        if bytes.count == 1 && isAbsolute {
            self.init(__unchecked: (), segments: [], isAbsolute: true)
            return
        }

        // Validate path characters (pchar / "/" / "?")
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

            // Check for newlines (invalid in paths)
            if byte == 0x0A || byte == 0x0D {
                throw Error.invalidCharacter(
                    String(decoding: bytes, as: UTF8.self),
                    byte: byte,
                    reason: "Path cannot contain newlines"
                )
            }

            i = bytes.index(after: i)
        }

        // Parse segments
        let pathBytes = isAbsolute ? Array(bytes.dropFirst()) : Array(bytes)

        if pathBytes.isEmpty {
            self.init(__unchecked: (), segments: [], isAbsolute: isAbsolute)
            return
        }

        // Split by '/' (0x2F)
        var segments: [String] = []
        var currentSegment: [UInt8] = []

        for byte in pathBytes {
            if byte == 0x2F {  // '/'
                segments.append(String(decoding: currentSegment, as: UTF8.self))
                currentSegment = []
            } else {
                currentSegment.append(byte)
            }
        }
        segments.append(String(decoding: currentSegment, as: UTF8.self))

        self.init(__unchecked: (), segments: segments, isAbsolute: isAbsolute)
    }
}

// MARK: - Byte Serialization

extension [UInt8] {
    /// Creates ASCII byte representation of an RFC 3986 URI path
    ///
    /// This is the canonical serialization of paths to bytes.
    ///
    /// ## Category Theory
    ///
    /// This is the most universal serialization (natural transformation):
    /// - **Domain**: RFC_3986.URI.Path (structured data)
    /// - **Codomain**: [UInt8] (ASCII bytes)
    ///
    /// - Parameter path: The path to serialize
    public init(_ path: RFC_3986.URI.Path) {
        var bytes: [UInt8] = []

        if path.isAbsolute {
            bytes.append(0x2F)  // '/'
        }

        for (index, segment) in path.segments.enumerated() {
            if index > 0 {
                bytes.append(0x2F)  // '/'
            }
            bytes.append(contentsOf: segment.utf8)
        }

        self = bytes
    }
}

// MARK: - Public Initializers

extension RFC_3986.URI.Path {
    /// Creates a path from segments
    ///
    /// - Parameters:
    ///   - segments: The path segments (should not contain "/" or be percent-encoded)
    ///   - isAbsolute: Whether this is an absolute path (defaults to true)
    /// - Throws: `RFC_3986.URI.Path.Error` if segments contain invalid characters
    public init(segments: [String], isAbsolute: Bool = true) throws(Error) {
        // Validate segments don't contain path separators
        for segment in segments {
            if segment.contains("/") {
                throw Error.segmentContainsSeparator(segment)
            }
            // Check for invalid whitespace
            if segment.contains(where: { $0.isNewline || ($0.isWhitespace && $0 != " ") }) {
                throw Error.segmentContainsWhitespace(segment)
            }
        }

        self.init(__unchecked: (), segments: segments, isAbsolute: isAbsolute)
    }

    /// Creates a path from a string
    ///
    /// - Parameter string: The path string (e.g., "/users/123" or "docs/file.txt")
    /// - Throws: `RFC_3986.URI.Path.Error` if the path is invalid
    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: Array(string.utf8), in: ())
    }
}

// MARK: - Convenience Properties

extension RFC_3986.URI.Path {
    /// The string representation of the path
    ///
    /// Returns the path in the form "/segment1/segment2" for absolute paths
    /// or "segment1/segment2" for relative paths.
    public var string: String {
        String(decoding: [UInt8](self), as: UTF8.self)
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
    /// - Throws: `RFC_3986.URI.Path.Error` if the segment is invalid
    public func appending(_ segment: some StringProtocol) throws(Error) -> Self {
        var newSegments = segments
        newSegments.append(String(segment))
        return try Self(segments: newSegments, isAbsolute: isAbsolute)
    }

    /// Appends multiple path segments
    ///
    /// - Parameter segments: The segments to append
    /// - Returns: A new path with the segments appended
    /// - Throws: `RFC_3986.URI.Path.Error` if any segment is invalid
    public func appending(contentsOf segments: [String]) throws(Error) -> Self {
        var newSegments = self.segments
        newSegments.append(contentsOf: segments)
        return try Self(segments: newSegments, isAbsolute: isAbsolute)
    }

    /// Returns a new path with the last segment removed
    ///
    /// - Returns: A path with the last segment removed, or self if empty
    public func deletingLastSegment() -> Self {
        guard !segments.isEmpty else { return self }
        var newSegments = segments
        newSegments.removeLast()
        return Self(__unchecked: (), segments: newSegments, isAbsolute: isAbsolute)
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
        self.init(__unchecked: (), segments: elements, isAbsolute: true)
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
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        do {
            try self.init(string)
        } catch {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid path: \(error)"
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(string)
    }
}
