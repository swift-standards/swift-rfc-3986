// ===----------------------------------------------------------------------===//
//
// Copyright (c) 2025 Coen ten Thije Boonkkamp
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of project contributors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

// URI.Path.Error.swift
// swift-rfc-3986
//
// Path-level validation errors

extension RFC_3986.URI.Path {
    /// Errors that can occur during path validation
    ///
    /// These represent constraint violations for URI paths,
    /// as defined by RFC 3986 Section 3.3.
    public enum Error: Swift.Error, Sendable, Equatable {
        /// Path segment contains a path separator
        case segmentContainsSeparator(_ segment: String)

        /// Path segment contains invalid whitespace
        case segmentContainsWhitespace(_ segment: String)

        /// Path contains an invalid character
        case invalidCharacter(_ value: String, byte: UInt8, reason: String)

        /// Path contains malformed percent-encoding
        case invalidPercentEncoding(_ value: String, reason: String)
    }
}

// MARK: - CustomStringConvertible

extension RFC_3986.URI.Path.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .segmentContainsSeparator(let segment):
            return "Path segment cannot contain '/': \(segment)"
        case .segmentContainsWhitespace(let segment):
            return "Path segment contains invalid whitespace: \(segment)"
        case .invalidCharacter(let value, let byte, let reason):
            return "Path '\(value)' has invalid byte 0x\(String(byte, radix: 16)): \(reason)"
        case .invalidPercentEncoding(let value, let reason):
            return "Path '\(value)' has invalid percent-encoding: \(reason)"
        }
    }
}
