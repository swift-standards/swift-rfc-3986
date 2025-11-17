import Testing

@testable import RFC_3986

@Suite("URI Validation")
struct URIValidationTests {

    @Test("Valid HTTP URI")
    func validHTTP() {
        #expect(RFC_3986.isValidURI("https://example.com"))
        #expect(RFC_3986.isValidURI("http://example.com/path"))
        #expect(RFC_3986.isValidURI("https://example.com:8080/path?query=value"))
    }

    @Test("Valid HTTPS URI")
    func validHTTPS() {
        #expect(RFC_3986.isValidHTTP("https://example.com"))
        #expect(RFC_3986.isValidHTTP("http://example.com"))
        #expect(!RFC_3986.isValidHTTP("ftp://example.com"))
    }

    @Test("Valid URN URI")
    func validURN() {
        #expect(RFC_3986.isValidURI("urn:uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6"))
        #expect(RFC_3986.isValidURI("urn:isbn:0451450523"))
    }

    @Test("Valid mailto URI")
    func validMailto() {
        #expect(RFC_3986.isValidURI("mailto:user@example.com"))
    }

    @Test("Valid FTP URI")
    func validFTP() {
        #expect(RFC_3986.isValidURI("ftp://ftp.example.com/file.txt"))
    }

    @Test("Valid URI - relative references")
    func validRelativeReferences() {
        // RFC 3986 Section 4.2: relative references are valid URI references
        #expect(RFC_3986.isValidURI("/path/to/resource"))
        #expect(RFC_3986.isValidURI("?query=value"))
        #expect(RFC_3986.isValidURI("#fragment"))
        #expect(RFC_3986.isValidURI("../relative/path"))

        // Note: "example.com" without a scheme is technically a valid path (not a host)
        // per RFC 3986, even though it's ambiguous
        #expect(RFC_3986.isValidURI("example.com"))
    }

    @Test("Valid URI - empty string (same document reference)")
    func validEmptyString() {
        // Empty strings are valid as "same document reference"
        // Used in href="" and RFC 6570 expansion with undefined variables
        #expect(RFC_3986.isValidURI(""))

        // Can create a URI from empty string
        let uri = try? RFC_3986.URI("")
        #expect(uri != nil)
        #expect(uri?.value == "")
    }

    @Test("Invalid URI - non-ASCII characters")
    func invalidNonASCII() {
        // RFC 3986 requires ASCII-only characters
        #expect(!RFC_3986.isValidURI("https://example.com/寿司"))
        #expect(!RFC_3986.isValidURI("https://例え.jp"))
    }

    @Test("Valid URI - percent-encoded")
    func validPercentEncoded() {
        // Percent-encoded characters are valid ASCII
        #expect(RFC_3986.isValidURI("https://example.com/%E5%AF%BF%E5%8F%B8"))
    }
}

@Suite("URI Creation")
struct URICreationTests {

    @Test("Create URI from string literal")
    func createFromLiteral() {
        let uri = try! RFC_3986.URI("https://example.com")
        #expect(uri.value == "https://example.com")
    }

    @Test("Create URI with validation")
    func createWithValidation() throws {
        let string = "https://example.com/path"
        let uri = try RFC_3986.URI(string)
        #expect(uri.value == "https://example.com/path")
    }

    @Test("Create URI fails with invalid input")
    func createFailsWithInvalid() {
        let string = "not a uri"
        #expect(throws: RFC_3986.Error.self) {
            try RFC_3986.URI(string)
        }
    }

    @Test("Create URI fails with non-ASCII")
    func createFailsWithNonASCII() {
        let string = "https://example.com/寿司"
        #expect(throws: RFC_3986.Error.self) {
            try RFC_3986.URI(string)
        }
    }
}

@Suite("URI Normalization")
struct URINormalizationTests {

    @Test("Normalize scheme to lowercase")
    func normalizeScheme() throws {
        let string = "HTTPS://example.com"
        let uri = try RFC_3986.URI(string)
        let normalized = uri.normalized()
        #expect(normalized.value.hasPrefix("https://"))
    }

    @Test("Normalize host to lowercase")
    func normalizeHost() throws {
        let string = "https://EXAMPLE.COM"
        let uri = try RFC_3986.URI(string)
        let normalized = uri.normalized()
        #expect(normalized.value.contains("example.com"))
    }

    @Test("Remove default HTTP port")
    func removeDefaultHTTPPort() throws {
        let string = "http://example.com:80/path"
        let uri = try RFC_3986.URI(string)
        let normalized = uri.normalized()
        #expect(!normalized.value.contains(":80"))
    }

    @Test("Remove default HTTPS port")
    func removeDefaultHTTPSPort() throws {
        let string = "https://example.com:443/path"
        let uri = try RFC_3986.URI(string)
        let normalized = uri.normalized()
        #expect(!normalized.value.contains(":443"))
    }

    @Test("Remove default FTP port")
    func removeDefaultFTPPort() throws {
        let string = "ftp://example.com:21/file.txt"
        let uri = try RFC_3986.URI(string)
        let normalized = uri.normalized()
        #expect(!normalized.value.contains(":21"))
    }

    @Test("Keep non-default port")
    func keepNonDefaultPort() throws {
        let string = "https://example.com:8080/path"
        let uri = try RFC_3986.URI(string)
        let normalized = uri.normalized()
        #expect(normalized.value.contains(":8080"))
    }

    @Test("Remove dot segments from path")
    func removeDotSegments() throws {
        let string = "https://example.com/a/b/c/./../../g"
        let uri = try RFC_3986.URI(string)
        let normalized = uri.normalized()
        #expect(normalized.value.contains("/a/g"))
    }

    @Test("Remove leading dot segment")
    func removeLeadingDot() throws {
        let string = "https://example.com/./a/b"
        let uri = try RFC_3986.URI(string)
        let normalized = uri.normalized()
        #expect(normalized.value.contains("/a/b"))
    }

    @Test("Remove double dot segments")
    func removeDoubleDots() throws {
        let string = "https://example.com/a/../b"
        let uri = try RFC_3986.URI(string)
        let normalized = uri.normalized()
        #expect(normalized.value.contains("/b"))
        #expect(!normalized.value.contains("/a/"))
    }
}

@Suite("URI Component Parsing")
struct URIComponentParsingTests {

    @Test("Parse scheme")
    func parseScheme() throws {
        let string = "https://example.com"
        let uri = try RFC_3986.URI(string)
        #expect(uri.scheme?.value == "https")
    }

    @Test("Parse host")
    func parseHost() throws {
        let string = "https://example.com/path"
        let uri = try RFC_3986.URI(string)
        #expect(uri.host?.rawValue == "example.com")
    }

    @Test("Parse port")
    func parsePort() throws {
        let string = "https://example.com:8080/path"
        let uri = try RFC_3986.URI(string)
        #expect(uri.port == 8080)
    }

    @Test("Parse path")
    func parsePath() throws {
        let string = "https://example.com/path/to/resource"
        let uri = try RFC_3986.URI(string)
        #expect(uri.path?.string == "/path/to/resource")
    }

    @Test("Parse query")
    func parseQuery() throws {
        let string = "https://example.com/path?key=value&foo=bar"
        let uri = try RFC_3986.URI(string)
        #expect(uri.query?.string == "key=value&foo=bar")
    }

    @Test("Parse fragment")
    func parseFragment() throws {
        let string = "https://example.com/path#section"
        let uri = try RFC_3986.URI(string)
        #expect(uri.fragment?.value == "section")
    }

    @Test("Parse all components")
    func parseAllComponents() throws {
        let string = "https://example.com:8080/path?query=value#section"
        let uri = try RFC_3986.URI(string)
        #expect(uri.scheme?.value == "https")
        #expect(uri.host?.rawValue == "example.com")
        #expect(uri.port == 8080)
        #expect(uri.path?.string == "/path")
        #expect(uri.query?.string == "query=value")
        #expect(uri.fragment?.value == "section")
    }
}

// NOTE: URL conformance tests removed - URL conformance moved to coenttb/swift-uri (Phase 3)
// See /Users/coen/Developer/URI_ARCHITECTURE_PLAN.md for details

@Suite("Path Normalization Algorithm")
struct PathNormalizationTests {

    @Test("Remove single dot")
    func removeSingleDot() {
        let input = "/a/./b"
        let output = RFC_3986.removeDotSegments(from: input)
        #expect(output == "/a/b")
    }

    @Test("Remove double dots")
    func removeDoubleDots() {
        let input = "/a/b/../c"
        let output = RFC_3986.removeDotSegments(from: input)
        #expect(output == "/a/c")
    }

    @Test("Complex path normalization")
    func complexNormalization() {
        let input = "/a/b/c/./../../g"
        let output = RFC_3986.removeDotSegments(from: input)
        #expect(output == "/a/g")
    }

    @Test("Leading dots")
    func leadingDots() {
        let input = "../a/b"
        let output = RFC_3986.removeDotSegments(from: input)
        #expect(output == "a/b")
    }

    @Test("Trailing dot")
    func trailingDot() {
        let input = "/a/b/."
        let output = RFC_3986.removeDotSegments(from: input)
        #expect(output == "/a/b/")
    }

    @Test("RFC 3986 Example 1")
    func rfc3986Example1() {
        let input = "/a/b/c/./../../g"
        let output = RFC_3986.removeDotSegments(from: input)
        #expect(output == "/a/g")
    }

    @Test("RFC 3986 Example 2")
    func rfc3986Example2() {
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
        #expect(normalized.path?.string == "/hello-world")
        #expect(normalized.value == "https://example.com/hello-world")
    }

    @Test
    func `Normalizes query percent-encoding`() throws {
        let uri = try RFC_3986.URI("https://example.com?key%3dvalue")
        let normalized = uri.normalizePercentEncoding()

        // = is reserved in query, should stay encoded but uppercase
        #expect(normalized.query?.string.contains("%3D") == true)
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
        #expect(normalized.path?.string == "/test-path")
        #expect(normalized.query?.string.contains("key-name") == true)
    }
}
