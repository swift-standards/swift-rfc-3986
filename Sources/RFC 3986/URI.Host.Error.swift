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

// URI.Host.Error.swift
// swift-rfc-3986
//
// Host-level validation errors

extension RFC_3986.URI.Host {
    /// Errors that can occur during host validation
    ///
    /// These represent constraint violations for URI hosts,
    /// as defined by RFC 3986 Section 3.2.2.
    public enum Error: Swift.Error, Sendable, Equatable {
        /// Host is empty
        case empty

        /// IPv6 address is malformed
        case invalidIPv6(_ value: String, reason: String)

        /// IPv4 address is malformed
        case invalidIPv4(_ value: String, reason: String)

        /// Registered name is malformed
        case invalidRegisteredName(_ value: String, reason: String)

        /// Host contains an invalid character
        case invalidCharacter(_ value: String, byte: UInt8, reason: String)
    }
}

// MARK: - CustomStringConvertible

extension RFC_3986.URI.Host.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .empty:
            return "Host cannot be empty"
        case .invalidIPv6(let value, let reason):
            return "Invalid IPv6 address '\(value)': \(reason)"
        case .invalidIPv4(let value, let reason):
            return "Invalid IPv4 address '\(value)': \(reason)"
        case .invalidRegisteredName(let value, let reason):
            return "Invalid registered name '\(value)': \(reason)"
        case .invalidCharacter(let value, let byte, let reason):
            return "Host '\(value)' has invalid byte 0x\(String(byte, radix: 16)): \(reason)"
        }
    }
}
