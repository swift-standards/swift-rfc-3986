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

// URI.Port.Error.swift
// swift-rfc-3986
//
// Port-level validation errors

extension RFC_3986.URI.Port {
    /// Errors that can occur during port validation
    ///
    /// These represent constraint violations for URI ports,
    /// as defined by RFC 3986 Section 3.2.3.
    public enum Error: Swift.Error, Sendable, Equatable {
        /// Port is empty
        case empty

        /// Port contains non-digit characters
        case invalidCharacter(_ value: String, byte: UInt8)

        /// Port value overflows UInt16 (max 65535)
        case overflow(_ value: String)
    }
}

// MARK: - CustomStringConvertible

extension RFC_3986.URI.Port.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .empty:
            return "Port cannot be empty"
        case .invalidCharacter(let value, let byte):
            return "Port '\(value)' contains invalid byte 0x\(String(byte, radix: 16)): only digits allowed"
        case .overflow(let value):
            return "Port '\(value)' overflows maximum value of 65535"
        }
    }
}
