# swift-rfc-3986

[![CI](https://github.com/swift-web-standards/swift-rfc-3986/workflows/CI/badge.svg)](https://github.com/swift-web-standards/swift-rfc-3986/actions/workflows/ci.yml)
![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Swift implementation of RFC 3986: Uniform Resource Identifier (URI) Generic Syntax

## Overview

This package provides a Swift implementation of URIs (Uniform Resource Identifiers) as defined in [RFC 3986](https://www.ietf.org/rfc/rfc3986.txt). URIs provide a simple and extensible means for identifying resources using a restricted set of ASCII characters to ensure maximum compatibility across different systems and protocols.

## Features

- ✅ URI validation (ASCII-only per RFC 3986)
- ✅ URI normalization (scheme/host lowercasing, default port removal)
- ✅ Component parsing (scheme, authority, path, query, fragment)
- ✅ Path segment normalization (dot-segment removal per RFC 3986 Section 5.2.4)
- ✅ Relative URI reference detection and resolution (RFC 3986 Section 5)
- ✅ Percent-encoding/decoding utilities (RFC 3986 Section 2.1)
- ✅ Character set definitions (reserved, unreserved, etc. per RFC 3986 Section 2)
- ✅ HTTP/HTTPS specific validation
- ✅ Protocol-based design with `URI.Representable`
- ✅ Foundation `URL` conformance to `URI.Representable`
- ✅ Swift 6 strict concurrency support
- ✅ Full `Sendable` conformance

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/swift-web-standards/swift-rfc-3986", from: "0.1.0")
]
```

## Usage

### Creating URIs

```swift
import RFC_3986

// From string literal (no validation)
let uri: RFC_3986.URI = "https://example.com/path"

// With validation
let validatedURI = try RFC_3986.URI("https://example.com/path")
print(validatedURI.value) // "https://example.com/path"
```

### Using Foundation URL

Foundation's `URL` type conforms to `URI.Representable`, allowing seamless interoperability:

```swift
let url = URL(string: "https://example.com")!

// URL conforms to URI.Representable
func process(uri: any RFC_3986.URI.Representable) {
    print(uri.uriString)
}

process(uri: url)  // Works!

// URL can be validated as HTTP URI
RFC_3986.isValidHTTP(url)  // true
```

### Validation

```swift
// Validate any URI string
if RFC_3986.isValidURI("https://example.com") {
    print("Valid URI")
}

// Validate HTTP(S) specifically
if RFC_3986.isValidHTTP("https://example.com") {
    print("Valid HTTP URI")
}

// Validate URI.Representable types
let url = URL(string: "https://example.com")!
if RFC_3986.isValidHTTP(url) {
    print("Valid HTTP URL")
}

// ASCII-only validation
RFC_3986.isValidURI("https://example.com/path")  // true
RFC_3986.isValidURI("https://example.com/寿司")   // false (non-ASCII)
RFC_3986.isValidURI("https://example.com/%E5%AF%BF%E5%8F%B8")  // true (percent-encoded)
```

### Normalization

```swift
let uri = try RFC_3986.URI("HTTPS://EXAMPLE.COM:443/path")
let normalized = uri.normalized()
print(normalized.value) // "https://example.com/path"
```

### Component Parsing

```swift
let uri = try RFC_3986.URI("https://example.com:8080/path?key=value#section")

print(uri.scheme)    // "https"
print(uri.host)      // "example.com"
print(uri.port)      // 8080
print(uri.path)      // "/path"
print(uri.query)     // "key=value"
print(uri.fragment)  // "section"
```

### URI Resolution

Resolve relative URI references against a base URI per RFC 3986 Section 5:

```swift
let base = try RFC_3986.URI("http://example.com/path/to/resource")

// Relative path
let relative1 = try base.resolve("../other")
print(relative1.value) // "http://example.com/path/other"

// Absolute path
let relative2 = try base.resolve("/newpath")
print(relative2.value) // "http://example.com/newpath"

// Query
let relative3 = try base.resolve("?query=value")
print(relative3.value) // "http://example.com/path/to/resource?query=value"

// Check if URI is relative
let uri = try RFC_3986.URI("https://example.com/path")
print(uri.isRelative) // false
```

### Percent-Encoding

```swift
// Encode a string
let encoded = RFC_3986.percentEncode("hello world?")
print(encoded) // "hello%20world%3F"

// Decode a percent-encoded string
let decoded = RFC_3986.percentDecode("hello%20world")
print(decoded) // "hello world"

// Normalize percent-encoding (uppercase hex, decode unreserved)
let normalized = RFC_3986.normalizePercentEncoding("hello%2fworld%2Dtest")
print(normalized) // "hello%2Fworld-test"

// Use character sets for component-specific encoding
let path = "path:with@special"
let encodedPath = RFC_3986.percentEncode(path, allowing: RFC_3986.CharacterSets.pathSegment)
// : and @ are allowed in path segments, so they won't be encoded
```

### Character Sets

Access RFC 3986 character set definitions:

```swift
// Unreserved characters (A-Z a-z 0-9 - . _ ~)
RFC_3986.CharacterSets.unreserved

// Reserved characters (: / ? # [ ] @ ! $ & ' ( ) * + , ; =)
RFC_3986.CharacterSets.reserved

// Component-specific character sets
RFC_3986.CharacterSets.scheme
RFC_3986.CharacterSets.userinfo
RFC_3986.CharacterSets.host
RFC_3986.CharacterSets.pathSegment
RFC_3986.CharacterSets.query
RFC_3986.CharacterSets.fragment
```

## URI vs IRI

**URI (Uniform Resource Identifier)**
- ASCII-only characters
- Used in protocols and systems
- Example: `https://example.com/%E5%AF%BF%E5%8F%B8`

**IRI (Internationalized Resource Identifier)**
- Allows Unicode characters
- User-friendly for international audiences
- Example: `https://例え.jp/寿司`

For IRI support with Unicode characters, see [swift-rfc-3987](https://github.com/swift-web-standards/swift-rfc-3987).

## RFC 3986 Compliance

This implementation provides lenient validation suitable for most use cases:
- ✅ Requires scheme (http, https, urn, mailto, ftp, etc.)
- ✅ Accepts only ASCII characters
- ✅ Supports percent-encoding
- ✅ Performs basic structure validation
- ✅ Normalizes according to RFC 3986 Section 6

For production use with strict compliance requirements, consider additional validation.

## Normalization Details

Per RFC 3986 Section 6, this implementation performs:

### Case Normalization (Section 6.2.2.1)
- Scheme and host components are normalized to lowercase
- Hexadecimal digits in percent-encoding are normalized to uppercase

### Percent-Encoding Normalization (Section 6.2.2.2)
- Foundation's URL handles percent-encoding normalization automatically

### Path Segment Normalization (Section 6.2.2.3)
- Removes dot segments ("." and "..") using the algorithm from Section 5.2.4
- Example: `/a/b/c/./../../g` → `/a/g`

### Scheme-Based Normalization
- Removes default ports (80 for HTTP, 443 for HTTPS, 21 for FTP)

## Related Packages

- [swift-rfc-3987](https://github.com/swift-web-standards/swift-rfc-3987) - Swift types for RFC 3987 (Internationalized Resource Identifiers)
- [swift-rfc-4287](https://github.com/swift-web-standards/swift-rfc-4287) - Swift types for RFC 4287 (Atom Syndication Format)
- [swift-atom](https://github.com/coenttb/swift-atom) - Atom feed generation and XML rendering

## Requirements

- Swift 6.0+
- macOS 14+, iOS 17+, tvOS 17+, watchOS 10+

## Related RFCs

- [RFC 3986](https://www.ietf.org/rfc/rfc3986.txt) - Uniform Resource Identifier (URI)
- [RFC 3987](https://www.ietf.org/rfc/rfc3987.txt) - Internationalized Resource Identifiers (IRIs)
- [RFC 4287](https://www.ietf.org/rfc/rfc4287.txt) - Atom Syndication Format

## License & Contributing

Licensed under Apache 2.0.

Contributions welcome! Please ensure:
- All tests pass
- Code follows existing style
- RFC 3986 compliance maintained
