import Testing

@testable import RFC_3986

@Suite
struct `String uri property` {

    @Test(arguments: [
        ("#fragment", nil as String?, nil as String?, "fragment"),
        ("#results", nil as String?, nil as String?, "results"),
        ("#", nil as String?, nil as String?, ""),
    ])
    func `Fragment-only URI`(
        input: String,
        expectedScheme: String?,
        expectedHost: String?,
        expectedFragment: String?
    ) {
        let uri = input.uri
        #expect(uri != nil)
        #expect(uri?.fragment?.value == expectedFragment)
        #expect(uri?.scheme?.value == expectedScheme)
        #expect(uri?.host?.rawValue == expectedHost)
    }

    @Test(arguments: [
        ("?query=value", "query=value"),
        ("?key=value&foo=bar", "key=value&foo=bar"),
        ("?", ""),
    ])
    func `Query-only URI`(input: String, expectedQuery: String) {
        let uri = input.uri
        #expect(uri != nil)
        #expect(uri?.query?.description == expectedQuery)
        #expect(uri?.scheme == nil)
        #expect(uri?.host == nil)
    }

    @Test(arguments: [
        ("https://user:pass@example.com", "user", "pass" as String?, "example.com"),
        ("http://admin:secret@localhost", "admin", "secret" as String?, "localhost"),
        ("ftp://john@example.com", "john", nil as String?, "example.com"),
    ])
    func `URI with userinfo`(
        input: String,
        expectedUser: String,
        expectedPassword: String?,
        expectedHost: String
    ) {
        let uri = input.uri
        #expect(uri != nil)
        #expect(uri?.userinfo?.user == expectedUser)
        #expect(uri?.userinfo?.password == expectedPassword)
        #expect(uri?.host?.rawValue == expectedHost)
    }

    @Test
    func `URI with all components`() {
        let uri = "https://user:pass@example.com:8080/path?query=value#fragment".uri

        #expect(uri?.scheme?.value == "https")
        #expect(uri?.userinfo?.user == "user")
        #expect(uri?.userinfo?.password == "pass")
        #expect(uri?.host?.rawValue == "example.com")
        #expect(uri?.port == 8080)
        #expect(uri?.path?.description == "/path")
        #expect(uri?.query?.description == "query=value")
        #expect(uri?.fragment?.value == "fragment")
    }

    @Test(arguments: [
        "not a valid uri 😀",
        "https://例え.jp",  // Non-ASCII host
        "http://host with spaces.com",
    ])
    func `Invalid URI returns nil`(input: String) {
        #expect(input.uri == nil)
    }

    @Test
    func `URI property is idempotent`() {
        let string = "https://example.com"
        let uri1 = string.uri
        let uri2 = string.uri

        #expect(uri1?.value == uri2?.value)
    }

    @Test
    func `Accessing URI methods`() {
        let uri = "https://example.com/hello%2dworld".uri

        // Should be able to call methods
        let normalized = uri?.normalizePercentEncoding()
        #expect(normalized?.value == "https://example.com/hello-world")

        let isHTTP = uri?.isHTTP
        #expect(isHTTP == true)

        let isSecure = uri?.isSecure
        #expect(isSecure == true)
    }
}

@Suite
struct `String percent encoding` {

    @Test
    func `RFC 3986 percent encoding uses uppercase hex`() {
        let input = "hello?world"
        let encoded = input.percentEncoded(allowing: .unreserved)

        // RFC 3986 uses UPPERCASE hex per Section 6.2.2.2
        #expect(encoded.contains("%3F"))  // Uppercase F
        #expect(!encoded.contains("%3f"))  // No lowercase f
    }

    @Test
    func `Percent encoding preserves unreserved characters`() {
        let unreserved = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
        let encoded = unreserved.percentEncoded(allowing: .unreserved)

        // Unreserved characters should not be encoded
        #expect(encoded == unreserved)
    }

    @Test
    func `Percent encoding encodes reserved characters`() {
        let input = "hello world!@#$%"
        let encoded = input.percentEncoded(allowing: .unreserved)

        // Space and special characters should be encoded
        #expect(encoded.contains("%20"))  // space
        #expect(encoded.contains("%21"))  // !
        #expect(encoded.contains("%40"))  // @
        #expect(encoded.contains("%23"))  // #
        #expect(encoded.contains("%24"))  // $
        #expect(encoded.contains("%25"))  // %
    }

    @Test
    func `Percent decoding handles multi-byte UTF-8`() {
        let encoded = "caf%C3%A9"  // café
        let decoded = encoded.percentDecoded()

        #expect(decoded == "café")
    }
}
