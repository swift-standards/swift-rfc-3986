import Testing
import Standards

@testable import RFC_3986

@Suite
struct `Developer Delight - Convenience APIs` {

    @Test
    func `String extension - percentEncoded()`() {
        let input = "hello world"
        let encoded = input.percentEncoded()
        #expect(encoded == "hello%20world")
    }

    @Test
    func `String extension - percentDecoded()`() {
        let input = "hello%20world"
        let decoded = input.percentDecoded()
        #expect(decoded == "hello world")
    }

    @Test
    func `String extension - uri property`() {
        #expect("https://example.com".uri != nil)
        #expect("not a uri".uri == nil)
    }

    @Test
    func `String extension - uri.isHTTP`() {
        #expect("https://example.com".uri?.isHTTP == true)
        #expect("ftp://example.com".uri?.isHTTP == false)
    }

    @Test
    func `String extension - uri parsing`() {
        let string = "https://example.com"
        let uri = string.uri
        #expect(uri?.value == "https://example.com")
    }

    @Test
    func `URI isSecure property`() throws {
        let httpsURI = try RFC_3986.URI("https://example.com")
        #expect(httpsURI.isSecure == true)

        let httpURI = try RFC_3986.URI("http://example.com")
        #expect(httpURI.isSecure == false)

        let wssURI = try RFC_3986.URI("wss://example.com")
        #expect(wssURI.isSecure == true)
    }

    @Test
    func `URI isHTTP property`() throws {
        let httpsURI = try RFC_3986.URI("https://example.com")
        #expect(httpsURI.isHTTP == true)

        let ftpURI = try RFC_3986.URI("ftp://example.com")
        #expect(ftpURI.isHTTP == false)
    }

    @Test
    func `URI base property`() throws {
        let uri = try RFC_3986.URI("https://example.com:8080/path?query#fragment")
        let base = uri.base
        #expect(base?.value == "https://example.com:8080")
    }

    @Test
    func `URI pathAndQuery property`() throws {
        let uri = try RFC_3986.URI("https://example.com/path?key=value")
        #expect(uri.pathAndQuery == "/path?key=value")

        let uriNoQuery = try RFC_3986.URI("https://example.com/path")
        #expect(uriNoQuery.pathAndQuery == "/path")
    }

    @Test
    func `appendingPathComponent()`() throws {
        let base = try RFC_3986.URI("https://example.com/path")
        let appended = try base.appendingPathComponent("file.txt")
        #expect(appended.value == "https://example.com/path/file.txt")

        // With trailing slash
        let baseWithSlash = try RFC_3986.URI("https://example.com/path/")
        let appendedWithSlash = try baseWithSlash.appendingPathComponent("file.txt")
        #expect(appendedWithSlash.value == "https://example.com/path/file.txt")
    }

    @Test
    func `appendingQueryItem()`() throws {
        let base = try RFC_3986.URI("https://example.com/path")
        let withQuery = try base.appendingQueryItem(name: "key", value: "value")
        #expect(withQuery.query?.string.contains("key=value") == true)

        // Append another
        let withTwoQueries = try withQuery.appendingQueryItem(name: "foo", value: "bar")
        #expect(withTwoQueries.query?.string.contains("key=value") == true)
        #expect(withTwoQueries.query?.string.contains("foo=bar") == true)
    }

    @Test
    func `settingFragment()`() throws {
        let base = try RFC_3986.URI("https://example.com/path")
        let withFragment = try base.settingFragment(try! RFC_3986.URI.Fragment("section"))
        #expect(withFragment.fragment?.value == "section")

        // Replace existing fragment
        let replaced = try withFragment.settingFragment(try! RFC_3986.URI.Fragment("other"))
        #expect(replaced.fragment?.value == "other")
    }
}

@Suite
struct `Developer Delight - Operators` {

    @Test
    func `/ operator for URI resolution - String`() throws {
        let base = try RFC_3986.URI("https://example.com/path/to/resource")
        let resolved = try base / "../other"
        #expect(resolved.value == "https://example.com/path/other")
    }

    @Test
    func `/ operator for URI resolution - URI`() throws {
        let base = try RFC_3986.URI("https://example.com/path/")
        let reference = try! RFC_3986.URI("file.txt")
        let resolved = try base / reference
        #expect(resolved.value.hasSuffix("file.txt"))
    }

    @Test
    func `Comparable - sorting URIs`() throws {
        let uri1 = try RFC_3986.URI("https://a.com")
        let uri2 = try RFC_3986.URI("https://b.com")
        let uri3 = try RFC_3986.URI("https://c.com")

        let sorted = [uri3, uri1, uri2].sorted()
        #expect(sorted[0].value == "https://a.com")
        #expect(sorted[1].value == "https://b.com")
        #expect(sorted[2].value == "https://c.com")
    }

    @Test
    func `Comparable - comparison`() throws {
        let uri1 = try RFC_3986.URI("https://a.com")
        let uri2 = try RFC_3986.URI("https://b.com")

        #expect(uri1 < uri2)
        #expect(uri2 > uri1)
        #expect(uri1 <= uri2)
        #expect(uri2 >= uri1)
    }
}

@Suite
struct `Developer Delight - Error Messages` {

    @Test
    func `Error description - invalidURI with non-ASCII`() {
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

    @Test
    func `Error description - invalidURI with invalid characters`() {
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

@Suite
struct `Developer Delight - Debug Output` {

    @Test
    func `CustomDebugStringConvertible - full URI`() throws {
        let uri = try RFC_3986.URI("https://example.com:8080/path?key=value#section")
        let debug = uri.debugDescription

        #expect(debug.contains("scheme: https"))
        #expect(debug.contains("host: example.com"))
        #expect(debug.contains("port: 8080"))
        #expect(debug.contains("path: /path"))
        #expect(debug.contains("query: key=value"))
        #expect(debug.contains("fragment: section"))
    }

    @Test
    func `CustomDebugStringConvertible - minimal URI`() throws {
        let uri = try RFC_3986.URI("https://example.com")
        let debug = uri.debugDescription

        #expect(debug.contains("scheme: https"))
        #expect(debug.contains("host: example.com"))
        #expect(!debug.contains("port:"))
        #expect(!debug.contains("query:"))
    }
}

@Suite
struct `Developer Delight - Fluent Chains` {

    @Test
    func `Chaining convenience methods`() throws {
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

    @Test
    func `URI method chaining`() {
        let encoded = "hello world?".percentEncoded()
        let result = encoded.uri?.normalizePercentEncoding().value

        #expect(result?.contains("%20") == true)
        #expect(result?.contains("%3F") == true)
    }
}
