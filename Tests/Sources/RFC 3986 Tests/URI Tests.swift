import Testing

@testable import RFC_3986

@Suite
struct `URI Validation` {

    @Test
    func `Valid HTTP URI`() {
        #expect(RFC_3986.isValidURI("https://example.com"))
        #expect(RFC_3986.isValidURI("http://example.com/path"))
        #expect(RFC_3986.isValidURI("https://example.com:8080/path?query=value"))
    }

    @Test
    func `Valid HTTPS URI`() {
        #expect(RFC_3986.isValidHTTP("https://example.com"))
        #expect(RFC_3986.isValidHTTP("http://example.com"))
        #expect(!RFC_3986.isValidHTTP("ftp://example.com"))
    }

    @Test
    func `Valid URN URI`() {
        #expect(RFC_3986.isValidURI("urn:uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6"))
        #expect(RFC_3986.isValidURI("urn:isbn:0451450523"))
    }

    @Test
    func `Valid mailto URI`() {
        #expect(RFC_3986.isValidURI("mailto:user@example.com"))
    }

    @Test
    func `Valid FTP URI`() {
        #expect(RFC_3986.isValidURI("ftp://ftp.example.com/file.txt"))
    }

    @Test
    func `Valid URI - relative references`() {
        // RFC 3986 Section 4.2: relative references are valid URI references
        #expect(RFC_3986.isValidURI("/path/to/resource"))
        #expect(RFC_3986.isValidURI("?query=value"))
        #expect(RFC_3986.isValidURI("#fragment"))
        #expect(RFC_3986.isValidURI("../relative/path"))

        // Note: "example.com" without a scheme is technically a valid path (not a host)
        // per RFC 3986, even though it's ambiguous
        #expect(RFC_3986.isValidURI("example.com"))
    }

    @Test
    func `Valid URI - empty string (same document reference)`() {
        // Empty strings are valid as "same document reference"
        // Used in href="" and RFC 6570 expansion with undefined variables
        #expect(RFC_3986.isValidURI(""))

        // Can create a URI from empty string
        let uri = try? RFC_3986.URI("")
        #expect(uri != nil)
        #expect(uri?.value == "")
    }

    @Test
    func `Invalid URI - non-ASCII characters`() {
        // RFC 3986 requires ASCII-only characters
        #expect(!RFC_3986.isValidURI("https://example.com/寿司"))
        #expect(!RFC_3986.isValidURI("https://例え.jp"))
    }

    @Test
    func `Valid URI - percent-encoded`() {
        // Percent-encoded characters are valid ASCII
        #expect(RFC_3986.isValidURI("https://example.com/%E5%AF%BF%E5%8F%B8"))
    }
}

@Suite
struct `URI Creation` {

    @Test
    func `Create URI from string literal`() {
        let uri = try! RFC_3986.URI("https://example.com")
        #expect(uri.value == "https://example.com")
    }

    @Test
    func `Create URI with validation`() throws {
        let string = "https://example.com/path"
        let uri = try RFC_3986.URI(string)
        #expect(uri.value == "https://example.com/path")
    }

    @Test
    func `Create URI fails with invalid input`() {
        let string = "not a uri"
        #expect(throws: RFC_3986.Error.self) {
            try RFC_3986.URI(string)
        }
    }

    @Test
    func `Create URI fails with non-ASCII`() {
        let string = "https://example.com/寿司"
        #expect(throws: RFC_3986.Error.self) {
            try RFC_3986.URI(string)
        }
    }
}

@Suite
struct `URI Normalization` {

    @Test
    func `Normalize scheme to lowercase`() throws {
        let string = "HTTPS://example.com"
        let uri = try RFC_3986.URI(string)
        let normalized = uri.normalized()
        #expect(normalized.value.hasPrefix("https://"))
    }

    @Test
    func `Normalize host to lowercase`() throws {
        let string = "https://EXAMPLE.COM"
        let uri = try RFC_3986.URI(string)
        let normalized = uri.normalized()
        #expect(normalized.value.contains("example.com"))
    }

    @Test
    func `Remove default HTTP port`() throws {
        let string = "http://example.com:80/path"
        let uri = try RFC_3986.URI(string)
        let normalized = uri.normalized()
        #expect(!normalized.value.contains(":80"))
    }

    @Test
    func `Remove default HTTPS port`() throws {
        let string = "https://example.com:443/path"
        let uri = try RFC_3986.URI(string)
        let normalized = uri.normalized()
        #expect(!normalized.value.contains(":443"))
    }

    @Test
    func `Remove default FTP port`() throws {
        let string = "ftp://example.com:21/file.txt"
        let uri = try RFC_3986.URI(string)
        let normalized = uri.normalized()
        #expect(!normalized.value.contains(":21"))
    }

    @Test
    func `Keep non-default port`() throws {
        let string = "https://example.com:8080/path"
        let uri = try RFC_3986.URI(string)
        let normalized = uri.normalized()
        #expect(normalized.value.contains(":8080"))
    }

    @Test
    func `Remove dot segments from path`() throws {
        let string = "https://example.com/a/b/c/./../../g"
        let uri = try RFC_3986.URI(string)
        let normalized = uri.normalized()
        #expect(normalized.value.contains("/a/g"))
    }

    @Test
    func `Remove leading dot segment`() throws {
        let string = "https://example.com/./a/b"
        let uri = try RFC_3986.URI(string)
        let normalized = uri.normalized()
        #expect(normalized.value.contains("/a/b"))
    }

    @Test
    func `Remove double dot segments`() throws {
        let string = "https://example.com/a/../b"
        let uri = try RFC_3986.URI(string)
        let normalized = uri.normalized()
        #expect(normalized.value.contains("/b"))
        #expect(!normalized.value.contains("/a/"))
    }
}

@Suite
struct `URI Component Parsing` {

    @Test
    func `Parse scheme`() throws {
        let string = "https://example.com"
        let uri = try RFC_3986.URI(string)
        #expect(uri.scheme?.value == "https")
    }

    @Test
    func `Parse host`() throws {
        let string = "https://example.com/path"
        let uri = try RFC_3986.URI(string)
        #expect(uri.host?.rawValue == "example.com")
    }

    @Test
    func `Parse port`() throws {
        let string = "https://example.com:8080/path"
        let uri = try RFC_3986.URI(string)
        #expect(uri.port == 8080)
    }

    @Test
    func `Parse path`() throws {
        let string = "https://example.com/path/to/resource"
        let uri = try RFC_3986.URI(string)
        #expect(uri.path?.description == "/path/to/resource")
    }

    @Test
    func `Parse query`() throws {
        let string = "https://example.com/path?key=value&foo=bar"
        let uri = try RFC_3986.URI(string)
        #expect(uri.query?.description == "key=value&foo=bar")
    }

    @Test
    func `Parse fragment`() throws {
        let string = "https://example.com/path#section"
        let uri = try RFC_3986.URI(string)
        #expect(uri.fragment?.value == "section")
    }

    @Test
    func `Parse all components`() throws {
        let string = "https://example.com:8080/path?query=value#section"
        let uri = try RFC_3986.URI(string)
        #expect(uri.scheme?.value == "https")
        #expect(uri.host?.rawValue == "example.com")
        #expect(uri.port == 8080)
        #expect(uri.path?.description == "/path")
        #expect(uri.query?.description == "query=value")
        #expect(uri.fragment?.value == "section")
    }
}

// NOTE: URL conformance tests removed - URL conformance moved to coenttb/swift-uri (Phase 3)
// See /Users/coen/Developer/URI_ARCHITECTURE_PLAN.md for details

@Suite
struct `Path Normalization Algorithm` {

    @Test
    func `Remove single dot`() {
        let input = "/a/./b"
        let output = RFC_3986.removeDotSegments(from: input)
        #expect(output == "/a/b")
    }

    @Test
    func `Remove double dots`() {
        let input = "/a/b/../c"
        let output = RFC_3986.removeDotSegments(from: input)
        #expect(output == "/a/c")
    }

    @Test
    func `Complex path normalization`() {
        let input = "/a/b/c/./../../g"
        let output = RFC_3986.removeDotSegments(from: input)
        #expect(output == "/a/g")
    }

    @Test
    func `Leading dots`() {
        let input = "../a/b"
        let output = RFC_3986.removeDotSegments(from: input)
        #expect(output == "a/b")
    }

    @Test
    func `Trailing dot`() {
        let input = "/a/b/."
        let output = RFC_3986.removeDotSegments(from: input)
        #expect(output == "/a/b/")
    }

    @Test
    func `RFC 3986 Example 1`() {
        let input = "/a/b/c/./../../g"
        let output = RFC_3986.removeDotSegments(from: input)
        #expect(output == "/a/g")
    }

    @Test
    func `RFC 3986 Example 2`() {
        let input = "mid/content=5/../6"
        let output = RFC_3986.removeDotSegments(from: input)
        #expect(output == "mid/6")
    }
}

@Suite
struct `URI normalizePercentEncoding()` {

    @Test
    func `Normalizes path percent-encoding`() throws {
        let uri = try RFC_3986.URI("https://example.com/hello%2dworld")
        let normalized = uri.normalizePercentEncoding()

        // Hyphen is unreserved, should be decoded
        #expect(normalized.path?.description == "/hello-world")
        #expect(normalized.value == "https://example.com/hello-world")
    }

    @Test
    func `Normalizes query percent-encoding`() throws {
        let uri = try RFC_3986.URI("https://example.com?key%3dvalue")
        let normalized = uri.normalizePercentEncoding()

        // = is reserved in query, should stay encoded but uppercase
        #expect(normalized.query?.description.contains("%3D") == true)
    }

    @Test
    func `Uppercases hex digits`() throws {
        let uri = try RFC_3986.URI("https://example.com/test%2fpath")
        let normalized = uri.normalizePercentEncoding()

        // Lowercase hex should become uppercase
        #expect(normalized.value.contains("%2F"))
        #expect(!normalized.value.contains("%2f"))
    }

    @Test
    func `Returns new URI instance`() throws {
        let uri = try RFC_3986.URI("https://example.com/test%2dpath")
        let normalized = uri.normalizePercentEncoding()

        // Should be different instances
        #expect(uri.value != normalized.value)
        #expect(uri.value == "https://example.com/test%2dpath")
        #expect(normalized.value == "https://example.com/test-path")
    }

    @Test
    func `Normalizes both path and query`() throws {
        let uri = try RFC_3986.URI("https://example.com/test%2dpath?key%2dname=value")
        let normalized = uri.normalizePercentEncoding()

        // Both should be normalized
        #expect(normalized.path?.description == "/test-path")
        #expect(normalized.query?.description.contains("key-name") == true)
    }
}
