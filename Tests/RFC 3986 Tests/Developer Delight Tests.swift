import Testing
import Standards

@testable import RFC_3986

@Suite("Developer Delight - Convenience APIs")
struct ConvenienceAPIsTests {

    @Test("String extension - percentEncoded()")
    func stringPercentEncoded() {
        let input = "hello world"
        let encoded = input.percentEncoded()
        #expect(encoded == "hello%20world")
    }

    @Test("String extension - percentDecoded()")
    func stringPercentDecoded() {
        let input = "hello%20world"
        let decoded = input.percentDecoded()
        #expect(decoded == "hello world")
    }

    @Test("String extension - uri property")
    func stringUriProperty() {
        #expect("https://example.com".uri != nil)
        #expect("not a uri".uri == nil)
    }

    @Test("String extension - uri.isHTTP")
    func stringUriIsHTTP() {
        #expect("https://example.com".uri?.isHTTP == true)
        #expect("ftp://example.com".uri?.isHTTP == false)
    }

    @Test("String extension - uri parsing")
    func stringUriParsing() {
        let string = "https://example.com"
        let uri = string.uri
        #expect(uri?.value == "https://example.com")
    }

    @Test("URI isSecure property")
    func uriIsSecure() throws {
        let httpsURI = try RFC_3986.URI("https://example.com")
        #expect(httpsURI.isSecure == true)

        let httpURI = try RFC_3986.URI("http://example.com")
        #expect(httpURI.isSecure == false)

        let wssURI = try RFC_3986.URI("wss://example.com")
        #expect(wssURI.isSecure == true)
    }

    @Test("URI isHTTP property")
    func uriIsHTTP() throws {
        let httpsURI = try RFC_3986.URI("https://example.com")
        #expect(httpsURI.isHTTP == true)

        let ftpURI = try RFC_3986.URI("ftp://example.com")
        #expect(ftpURI.isHTTP == false)
    }

    @Test("URI base property")
    func uriBase() throws {
        let uri = try RFC_3986.URI("https://example.com:8080/path?query#fragment")
        let base = uri.base
        #expect(base?.value == "https://example.com:8080")
    }

    @Test("URI pathAndQuery property")
    func uriPathAndQuery() throws {
        let uri = try RFC_3986.URI("https://example.com/path?key=value")
        #expect(uri.pathAndQuery == "/path?key=value")

        let uriNoQuery = try RFC_3986.URI("https://example.com/path")
        #expect(uriNoQuery.pathAndQuery == "/path")
    }

    @Test("appendingPathComponent()")
    func appendingPathComponent() throws {
        let base = try RFC_3986.URI("https://example.com/path")
        let appended = try base.appendingPathComponent("file.txt")
        #expect(appended.value == "https://example.com/path/file.txt")

        // With trailing slash
        let baseWithSlash = try RFC_3986.URI("https://example.com/path/")
        let appendedWithSlash = try baseWithSlash.appendingPathComponent("file.txt")
        #expect(appendedWithSlash.value == "https://example.com/path/file.txt")
    }

    @Test("appendingQueryItem()")
    func appendingQueryItem() throws {
        let base = try RFC_3986.URI("https://example.com/path")
        let withQuery = try base.appendingQueryItem(name: "key", value: "value")
        #expect(withQuery.query?.string.contains("key=value") == true)

        // Append another
        let withTwoQueries = try withQuery.appendingQueryItem(name: "foo", value: "bar")
        #expect(withTwoQueries.query?.string.contains("key=value") == true)
        #expect(withTwoQueries.query?.string.contains("foo=bar") == true)
    }

    @Test("settingFragment()")
    func settingFragment() throws {
        let base = try RFC_3986.URI("https://example.com/path")
        let withFragment = try base.settingFragment(try! RFC_3986.URI.Fragment("section"))
        #expect(withFragment.fragment?.value == "section")

        // Replace existing fragment
        let replaced = try withFragment.settingFragment(try! RFC_3986.URI.Fragment("other"))
        #expect(replaced.fragment?.value == "other")
    }
}

@Suite("Developer Delight - Operators")
struct OperatorsTests {

    @Test("/ operator for URI resolution - String")
    func operatorResolveString() throws {
        let base = try RFC_3986.URI("https://example.com/path/to/resource")
        let resolved = try base / "../other"
        #expect(resolved.value == "https://example.com/path/other")
    }

    @Test("/ operator for URI resolution - URI")
    func operatorResolveURI() throws {
        let base = try RFC_3986.URI("https://example.com/path/")
        let reference = try! RFC_3986.URI("file.txt")
        let resolved = try base / reference
        #expect(resolved.value.hasSuffix("file.txt"))
    }

    @Test("Comparable - sorting URIs")
    func comparableSorting() throws {
        let uri1 = try RFC_3986.URI("https://a.com")
        let uri2 = try RFC_3986.URI("https://b.com")
        let uri3 = try RFC_3986.URI("https://c.com")

        let sorted = [uri3, uri1, uri2].sorted()
        #expect(sorted[0].value == "https://a.com")
        #expect(sorted[1].value == "https://b.com")
        #expect(sorted[2].value == "https://c.com")
    }

    @Test("Comparable - comparison")
    func comparableComparison() throws {
        let uri1 = try RFC_3986.URI("https://a.com")
        let uri2 = try RFC_3986.URI("https://b.com")

        #expect(uri1 < uri2)
        #expect(uri2 > uri1)
        #expect(uri1 <= uri2)
        #expect(uri2 >= uri1)
    }
}

@Suite("Developer Delight - Error Messages")
struct ErrorMessagesTests {

    @Test("Error description - invalidURI with non-ASCII")
    func errorDescriptionInvalidURINonASCII() {
        do {
            let string = "https://example.com/寿司"
            _ = try RFC_3986.URI(string)
            Issue.record("Should have thrown an error")
        } catch let error as RFC_3986.Error {
            #expect(error.description.contains("ASCII"))
        } catch {
            Issue.record("Wrong error type")
        }
    }

    @Test("Error description - invalidURI with invalid characters")
    func errorDescriptionInvalidURIWithInvalidChars() {
        do {
            let string = "http://example.com/<invalid>"
            _ = try RFC_3986.URI(string)
            Issue.record("Should have thrown an error")
        } catch let error as RFC_3986.Error {
            #expect(error.description.contains("RFC 3986"))
        } catch {
            Issue.record("Wrong error type")
        }
    }
}

@Suite("Developer Delight - Debug Output")
struct DebugOutputTests {

    @Test("CustomDebugStringConvertible - full URI")
    func debugDescriptionFull() throws {
        let uri = try RFC_3986.URI("https://example.com:8080/path?key=value#section")
        let debug = uri.debugDescription

        #expect(debug.contains("scheme: https"))
        #expect(debug.contains("host: example.com"))
        #expect(debug.contains("port: 8080"))
        #expect(debug.contains("path: /path"))
        #expect(debug.contains("query: key=value"))
        #expect(debug.contains("fragment: section"))
    }

    @Test("CustomDebugStringConvertible - minimal URI")
    func debugDescriptionMinimal() throws {
        let uri = try RFC_3986.URI("https://example.com")
        let debug = uri.debugDescription

        #expect(debug.contains("scheme: https"))
        #expect(debug.contains("host: example.com"))
        #expect(!debug.contains("port:"))
        #expect(!debug.contains("query:"))
    }
}

@Suite("Developer Delight - Fluent Chains")
struct FluentChainsTests {

    @Test("Chaining convenience methods")
    func chainingMethods() throws {
        let uri = try RFC_3986.URI("https://example.com")
            .appendingPathComponent("api")
            .appendingPathComponent("users")
            .appendingQueryItem(name: "page", value: "1")
            .appendingQueryItem(name: "limit", value: "10")
            .settingFragment(try! RFC_3986.URI.Fragment("results"))

        #expect(uri.value.contains("/api/users"))
        #expect(uri.query?.string.contains("page=1") == true)
        #expect(uri.query?.string.contains("limit=10") == true)
        #expect(uri.fragment?.value == "results")
    }

    @Test("URI method chaining")
    func uriChaining() {
        let encoded = "hello world?".percentEncoded()
        let result = encoded.uri?.normalizePercentEncoding().value

        #expect(result?.contains("%20") == true)
        #expect(result?.contains("%3F") == true)
    }
}
