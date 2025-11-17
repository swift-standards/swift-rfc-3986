import Foundation
import Testing

@testable import RFC_3986

@Suite("README Verification")
struct ReadmeVerificationTests {

    @Test("Creating URIs - from string literal")
    func creatingURIsStringLiteral() {
        // From README example
        let uri: RFC_3986.URI = "https://example.com/path"

        #expect(uri.value == "https://example.com/path")
    }

    @Test("Creating URIs - with validation")
    func creatingURIsValidation() throws {
        // From README example
        let string = "https://example.com/path"
        let validatedURI = try RFC_3986.URI(string)

        #expect(validatedURI.value == "https://example.com/path")
    }

    @Test("Using Foundation URL - URI.Representable conformance")
    func foundationURLConformance() {
        // From README example
        let url = URL(string: "https://example.com")!

        // URL conforms to URI.Representable
        func process(uri: any RFC_3986.URI.Representable) -> String {
            return uri.uriString
        }

        let result = process(uri: url)
        #expect(result == "https://example.com")
    }

    @Test("Using Foundation URL - HTTP validation")
    func foundationURLHTTPValidation() {
        // From README example
        let url = URL(string: "https://example.com")!
        let isValid = RFC_3986.isValidHTTP(url)

        #expect(isValid == true)
    }

    @Test("Validation - validate URI string")
    func validationURIString() {
        // From README example
        let isValid = RFC_3986.isValidURI("https://example.com")

        #expect(isValid == true)
    }

    @Test("Validation - validate HTTP specifically")
    func validationHTTP() {
        // From README example
        let isValid = RFC_3986.isValidHTTP("https://example.com")

        #expect(isValid == true)
    }

    @Test("Validation - validate URI.Representable types")
    func validationRepresentableTypes() {
        // From README example
        let url = URL(string: "https://example.com")!
        let isValid = RFC_3986.isValidHTTP(url)

        #expect(isValid == true)
    }

    @Test("Normalization example")
    func normalizationExample() throws {
        // From README example
        let string = "HTTPS://EXAMPLE.COM:443/path"
        let uri = try RFC_3986.URI(string)
        let normalized = uri.normalized()

        #expect(normalized.value == "https://example.com/path")
    }

    @Test("RFC 3986 Compliance - supports relative references")
    func complianceSupportsRelativeReferences() {
        // RFC 3986 Section 4.1: URI-reference = URI / relative-ref
        let absoluteURI = RFC_3986.isValidURI("https://example.com")
        let relativeRef = RFC_3986.isValidURI("/path/to/resource")
        let queryRef = RFC_3986.isValidURI("?query=value")
        let fragmentRef = RFC_3986.isValidURI("#fragment")

        #expect(absoluteURI == true)
        #expect(relativeRef == true)
        #expect(queryRef == true)
        #expect(fragmentRef == true)
    }

    @Test("RFC 3986 Compliance - ASCII only")
    func complianceASCIIOnly() {
        // From README example - URIs must be ASCII only
        let asciiURI = RFC_3986.isValidURI("https://example.com/path")
        let unicodeURI = RFC_3986.isValidURI("https://example.com/寿司")

        #expect(asciiURI == true)
        #expect(unicodeURI == false)
    }

    @Test("RFC 3986 Compliance - percent-encoded URIs")
    func compliancePercentEncoded() throws {
        // From README example - Percent-encoded characters are valid
        let string = "https://example.com/%E5%AF%BF%E5%8F%B8"
        let uri = try RFC_3986.URI(string)

        #expect(uri.value.contains("%E5%AF%BF%E5%8F%B8"))
    }

    @Test("Protocol-based design - URI.Representable")
    func protocolBasedDesign() {
        // From README example
        let url = URL(string: "https://test.com")!

        // URL should conform to URI.Representable
        let representable: any RFC_3986.URI.Representable = url
        #expect(representable.uriString == "https://test.com")
    }

    @Test("Component parsing - scheme")
    func componentParsingScheme() throws {
        // From README example
        let string = "https://example.com"
        let uri = try RFC_3986.URI(string)

        #expect(uri.scheme?.value == "https")
    }

    @Test("Component parsing - host")
    func componentParsingHost() throws {
        // From README example
        let string = "https://example.com/path"
        let uri = try RFC_3986.URI(string)

        #expect(uri.host?.rawValue == "example.com")
    }

    @Test("Component parsing - port")
    func componentParsingPort() throws {
        // From README example
        let string = "https://example.com:8080"
        let uri = try RFC_3986.URI(string)

        #expect(uri.port == 8080)
    }

    @Test("Component parsing - path")
    func componentParsingPath() throws {
        // From README example
        let string = "https://example.com/path/to/resource"
        let uri = try RFC_3986.URI(string)

        #expect(uri.path?.string == "/path/to/resource")
    }

    @Test("Component parsing - query")
    func componentParsingQuery() throws {
        // From README example
        let string = "https://example.com?key=value"
        let uri = try RFC_3986.URI(string)

        #expect(uri.query?.string == "key=value")
    }

    @Test("Component parsing - fragment")
    func componentParsingFragment() throws {
        // From README example
        let string = "https://example.com#section"
        let uri = try RFC_3986.URI(string)

        #expect(uri.fragment?.value == "section")
    }
}
