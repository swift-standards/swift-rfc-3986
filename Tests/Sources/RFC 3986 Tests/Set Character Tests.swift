import Testing

@testable import RFC_3986

@Suite
struct `Set<Character> uri namespace` {

    @Test
    func `URI namespace syntax works`() {
        // Test that .uri.reserved syntax works and returns CharacterSet
        let reserved: Set<Character> = .uri.reserved
        #expect(reserved.contains(":"))
        #expect(reserved.contains("/"))

        // Test a few other properties to ensure the namespace works correctly
        let unreserved: Set<Character> = .uri.unreserved
        #expect(unreserved.contains("a"))
        #expect(unreserved.contains("-"))

        let query: Set<Character> = .uri.query
        #expect(query.contains("?"))
        #expect(query.contains("&"))
    }
}
