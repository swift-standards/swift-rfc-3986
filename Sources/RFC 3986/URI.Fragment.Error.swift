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

// URI.Fragment.Error.swift
// swift-rfc-3986
//
// Fragment-level validation errors

extension RFC_3986.URI.Fragment {
    /// Errors that can occur during fragment validation
    ///
    /// These represent constraint violations for URI fragments,
    /// as defined by RFC 3986 Section 3.5.
    public enum Error: Swift.Error, Sendable, Equatable {
        /// Fragment contains the hash character '#'
        case containsHash(_ value: String)

        /// Fragment contains a newline character
        case containsNewline(_ value: String)

        /// Fragment contains an invalid character
        case invalidCharacter(_ value: String, byte: UInt8, reason: String)
    }
}

// MARK: - CustomStringConvertible

extension RFC_3986.URI.Fragment.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .containsHash(let value):
            return "Fragment '\(value)' cannot contain '#' character"
        case .containsNewline(let value):
            return "Fragment '\(value)' cannot contain newline characters"
        case .invalidCharacter(let value, let byte, let reason):
            return "Fragment '\(value)' has invalid byte 0x\(String(byte, radix: 16)): \(reason)"
        }
    }
}
