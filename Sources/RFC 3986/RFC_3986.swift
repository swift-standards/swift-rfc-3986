
/// RFC 3986: Uniform Resource Identifier (URI) Generic Syntax
///
/// This module implements Uniform Resource Identifiers (URIs)
/// as specified in RFC 3986. URIs provide a standard way to identify
/// resources using ASCII characters.
///
/// Example usage:
/// ```swift
/// // Create and validate a URI
/// let uri = try RFC_3986.URI("https://example.com/path")
///
/// // Resolve relative references
/// let resolved = try uri.resolve("../other")
///
/// // Access components
/// print(uri.scheme) // "https"
/// print(uri.host)   // "example.com"
/// ```
public enum RFC_3986 {}
