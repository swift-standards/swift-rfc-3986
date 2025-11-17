import Testing
@testable import RFC_3986

@Suite
struct `String uri property` {

    @Test(arguments: [
        ("#fragment", nil as String?, nil as String?, "fragment"),
        ("#results", nil as String?, nil as String?, "results"),
        ("#", nil as String?, nil as String?, "")
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
        ("?", "")
    ])
    func `Query-only URI`(input: String, expectedQuery: String) {
        let uri = input.uri
        #expect(uri != nil)
        #expect(uri?.query?.string == expectedQuery)
        #expect(uri?.scheme == nil)
        #expect(uri?.host == nil)
    }

    @Test(arguments: [
        ("https://user:pass@example.com", "user", "pass" as String?, "example.com"),
        ("http://admin:secret@localhost", "admin", "secret" as String?, "localhost"),
        ("ftp://john@example.com", "john", nil as String?, "example.com")
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
        #expect(uri?.path?.string == "/path")
        #expect(uri?.query?.string == "query=value")
        #expect(uri?.fragment?.value == "fragment")
    }

    @Test(arguments: [
        "not a valid uri 😀",
        "https://例え.jp",  // Non-ASCII host
        "http://host with spaces.com"
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
    func `swift-standards defaults to lowercase hex`() {
        let input = "hello world"
        let encoded = input.percentEncoded(allowing: Set("abcdefghijklmnopqrstuvwxyz"))

        // swift-standards default is lowercase
        #expect(encoded.contains("%20"))
        // This is testing the generic implementation, which uses lowercase by default
    }

    @Test
    func `swift-standards supports uppercase via parameter`() {
        let input = "hello world"
        let encoded = String.percentEncoded(
            string: input,
            allowing: Set("abcdefghijklmnopqrstuvwxyz"),
            uppercaseHex: true
        )

        #expect(encoded.contains("%20"))
        #expect(!encoded.contains("%2a"))
    }

    @Test
    func `RFC CharacterSet overload uses uppercase`() {
        let input = "hello?world"
        let encoded = input.percentEncoded(allowing: .unreserved)

        // Should use UPPERCASE (RFC default)
        #expect(encoded.contains("%3F"))  // Uppercase F
        #expect(!encoded.contains("%3f"))  // No lowercase f
    }
}
