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

// URI.Query.Error.swift
// swift-rfc-3986
//
// Query-level validation errors

extension RFC_3986.URI.Query {
    /// Errors that can occur during query validation
    ///
    /// These represent constraint violations for URI queries,
    /// as defined by RFC 3986 Section 3.4.
    public enum Error: Swift.Error, Sendable, Equatable {
        /// Query parameter key is empty
        case emptyKey

        /// Query parameter key contains newline
        case keyContainsNewline(_ key: String)

        /// Query parameter value contains newline
        case valueContainsNewline(_ key: String, value: String)

        /// Query contains an invalid character
        case invalidCharacter(_ value: String, byte: UInt8, reason: String)

        /// Query contains malformed percent-encoding
        case invalidPercentEncoding(_ value: String, reason: String)
    }
}

// MARK: - CustomStringConvertible

extension RFC_3986.URI.Query.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .emptyKey:
            return "Query parameter key cannot be empty"
        case .keyContainsNewline(let key):
            return "Query parameter key '\(key)' contains newline"
        case .valueContainsNewline(let key, let value):
            return "Query parameter '\(key)' has value '\(value)' containing newline"
        case .invalidCharacter(let value, let byte, let reason):
            return "Query '\(value)' has invalid byte 0x\(String(byte, radix: 16)): \(reason)"
        case .invalidPercentEncoding(let value, let reason):
            return "Query '\(value)' has invalid percent-encoding: \(reason)"
        }
    }
}
