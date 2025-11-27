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

// URI.Scheme.Error.swift
// swift-rfc-3986
//
// Scheme-level validation errors

extension RFC_3986.URI.Scheme {
    /// Errors that can occur during scheme validation
    ///
    /// These represent constraint violations for URI schemes,
    /// as defined by RFC 3986 Section 3.1.
    public enum Error: Swift.Error, Sendable, Equatable {
        /// Scheme is empty
        case empty

        /// Scheme does not start with a letter (ALPHA)
        case invalidStart(_ value: String, byte: UInt8)

        /// Scheme contains an invalid character
        case invalidCharacter(_ value: String, byte: UInt8, reason: String)
    }
}

// MARK: - CustomStringConvertible

extension RFC_3986.URI.Scheme.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .empty:
            return "Scheme cannot be empty"
        case .invalidStart(let value, let byte):
            return "Scheme '\(value)' must start with a letter, got 0x\(String(byte, radix: 16))"
        case .invalidCharacter(let value, let byte, let reason):
            return "Scheme '\(value)' has invalid byte 0x\(String(byte, radix: 16)): \(reason)"
        }
    }
}
