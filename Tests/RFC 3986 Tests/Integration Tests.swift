import Testing
@testable import RFC_3986

@Suite("swift-standards Integration")
struct StandardsIntegrationTests {

    @Test
    func `RFC overload delegates to swift-standards`() {
        let input = "hello world"

        // RFC version with CharacterSet
        let rfcEncoded = input.percentEncoded(allowing: .unreserved)

        // Direct swift-standards version with Set<Character>
        let standardsEncoded = String.percentEncoded(
            string: input,
            allowing: RFC_3986.CharacterSet.unreserved.characters,
            uppercaseHex: true
        )

        // Should produce same result
        #expect(rfcEncoded == standardsEncoded)
    }

    @Test
    func `Decoding uses swift-standards implementation`() {
        let encoded = "hello%20world"

        // RFC decoding
        let rfcDecoded = RFC_3986.percentDecode(encoded)

        // swift-standards decoding
        let standardsDecoded = String.percentDecoded(string: encoded)

        // Should produce same result
        #expect(rfcDecoded == standardsDecoded)
    }
}
