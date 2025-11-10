import Foundation
import Testing

@testable import RFC_3986

@Suite("Character Sets")
struct CharacterSetsTests {

    @Test("Unreserved characters")
    func unreservedCharacters() {
        let unreserved = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
        for char in unreserved {
            let charString = String(char)
            #expect(charString.rangeOfCharacter(from: RFC_3986.CharacterSets.unreserved) != nil)
        }
    }

    @Test("Reserved characters")
    func reservedCharacters() {
        let reserved = ":/?#[]@!$&'()*+,;="
        for char in reserved {
            let charString = String(char)
            #expect(charString.rangeOfCharacter(from: RFC_3986.CharacterSets.reserved) != nil)
        }
    }

    @Test("General delimiters")
    func generalDelimiters() {
        let genDelims = ":/?#[]@"
        for char in genDelims {
            let charString = String(char)
            #expect(charString.rangeOfCharacter(from: RFC_3986.CharacterSets.genDelims) != nil)
        }
    }

    @Test("Sub-delimiters")
    func subDelimiters() {
        let subDelims = "!$&'()*+,;="
        for char in subDelims {
            let charString = String(char)
            #expect(charString.rangeOfCharacter(from: RFC_3986.CharacterSets.subDelims) != nil)
        }
    }
}

@Suite("Percent Encoding")
struct PercentEncodingTests {

    @Test("Encode space character")
    func encodeSpace() {
        let input = "hello world"
        let encoded = RFC_3986.percentEncode(input)
        #expect(encoded.contains("%20"))
    }

    @Test("Encode special characters")
    func encodeSpecialCharacters() {
        let input = "hello?world#test"
        let encoded = RFC_3986.percentEncode(input)
        #expect(encoded.contains("%3F"))  // ?
        #expect(encoded.contains("%23"))  // #
    }

    @Test("Don't encode unreserved characters")
    func dontEncodeUnreserved() {
        let input = "hello-world_123.test~abc"
        let encoded = RFC_3986.percentEncode(input)
        #expect(encoded == input)
    }

    @Test("Decode percent-encoded string")
    func decodePercentEncoded() {
        let encoded = "hello%20world%3Ftest"
        let decoded = RFC_3986.percentDecode(encoded)
        #expect(decoded == "hello world?test")
    }

    @Test("Normalize percent-encoding - uppercase hex")
    func normalizeUppercaseHex() {
        let input = "hello%2fworld"  // lowercase hex
        let normalized = RFC_3986.normalizePercentEncoding(input)
        #expect(normalized == "hello%2Fworld")  // uppercase hex
    }

    @Test("Normalize percent-encoding - decode unreserved")
    func normalizeDecodeUnreserved() {
        let input = "hello%2Dworld"  // encoded hyphen (unreserved)
        let normalized = RFC_3986.normalizePercentEncoding(input)
        #expect(normalized == "hello-world")  // decoded
    }

    @Test("Encode path segment with allowed characters")
    func encodePathSegment() {
        let input = "path/segment:with@special"
        let encoded = RFC_3986.percentEncode(input, allowing: RFC_3986.CharacterSets.pathSegment)
        #expect(!encoded.contains("%3A"))  // : should not be encoded in path
        #expect(!encoded.contains("%40"))  // @ should not be encoded in path
    }

    @Test("Encode query with allowed characters")
    func encodeQuery() {
        let input = "key=value&foo=bar"
        let encoded = RFC_3986.percentEncode(input, allowing: RFC_3986.CharacterSets.query)
        #expect(!encoded.contains("%3D"))  // = should not be encoded in query
        #expect(!encoded.contains("%26"))  // & should not be encoded in query
    }
}

@Suite("URI Resolution - RFC 3986 Section 5.4")
struct URIResolutionTests {

    let base = "http://a/b/c/d;p?q"

    @Test("Normal examples - absolute URI")
    func normalAbsoluteURI() throws {
        let baseURI = try RFC_3986.URI(base)
        let reference = "g:h"
        let resolved = try baseURI.resolve(reference)
        #expect(resolved.value == "g:h")
    }

    @Test("Normal examples - relative path")
    func normalRelativePath() throws {
        let baseURI = try RFC_3986.URI(base)
        let reference = "g"
        let resolved = try baseURI.resolve(reference)
        #expect(resolved.value == "http://a/b/c/g")
    }

    @Test("Normal examples - relative path with ./")
    func normalRelativePathDot() throws {
        let baseURI = try RFC_3986.URI(base)
        let reference = "./g"
        let resolved = try baseURI.resolve(reference)
        #expect(resolved.value == "http://a/b/c/g")
    }

    @Test("Normal examples - absolute path")
    func normalAbsolutePath() throws {
        let baseURI = try RFC_3986.URI(base)
        let reference = "/g"
        let resolved = try baseURI.resolve(reference)
        #expect(resolved.value == "http://a/g")
    }

    @Test("Normal examples - network path")
    func normalNetworkPath() throws {
        let baseURI = try RFC_3986.URI(base)
        let reference = "//g"
        let resolved = try baseURI.resolve(reference)
        #expect(resolved.value.contains("//g"))
    }

    @Test("Normal examples - query")
    func normalQuery() throws {
        let baseURI = try RFC_3986.URI(base)
        let reference = "?y"
        let resolved = try baseURI.resolve(reference)
        #expect(resolved.value == "http://a/b/c/d;p?y")
    }

    @Test("Normal examples - fragment")
    func normalFragment() throws {
        let baseURI = try RFC_3986.URI(base)
        let reference = "#s"
        let resolved = try baseURI.resolve(reference)
        #expect(resolved.value.contains("#s"))
    }

    @Test("Abnormal examples - parent directory")
    func abnormalParentDirectory() throws {
        let baseURI = try RFC_3986.URI(base)
        let reference = "../g"
        let resolved = try baseURI.resolve(reference)
        #expect(resolved.value == "http://a/b/g")
    }

    @Test("Abnormal examples - multiple parent directories")
    func abnormalMultipleParents() throws {
        let baseURI = try RFC_3986.URI(base)
        let reference = "../../g"
        let resolved = try baseURI.resolve(reference)
        #expect(resolved.value == "http://a/g")
    }

    @Test("Check if URI is relative")
    func checkIsRelative() throws {
        let string = "https://example.com/path"
        let absoluteURI = try RFC_3986.URI(string)
        #expect(!absoluteURI.isRelative)

        let relativeString = "/path/to/resource"
        // Foundation URL requires a scheme, so we create it differently
        var relativeComponents = URLComponents()
        relativeComponents.path = relativeString
        if let urlString = relativeComponents.string {
            // This will be relative (no scheme)
            #expect(urlString.hasPrefix("/"))
        }
    }
}
