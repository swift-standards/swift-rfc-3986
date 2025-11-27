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

// URI.Userinfo.Error.swift
// swift-rfc-3986
//
// Userinfo-level validation errors

extension RFC_3986.URI.Userinfo {
    /// Errors that can occur during userinfo validation
    ///
    /// These represent constraint violations for URI userinfo,
    /// as defined by RFC 3986 Section 3.2.1.
    public enum Error: Swift.Error, Sendable, Equatable {
        /// Userinfo contains an invalid character
        case invalidCharacter(_ value: String, byte: UInt8, reason: String)

        /// Userinfo contains malformed percent-encoding
        case invalidPercentEncoding(_ value: String, reason: String)
    }
}

// MARK: - CustomStringConvertible

extension RFC_3986.URI.Userinfo.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidCharacter(let value, let byte, let reason):
            return "Userinfo '\(value)' has invalid byte 0x\(String(byte, radix: 16)): \(reason)"
        case .invalidPercentEncoding(let value, let reason):
            return "Userinfo '\(value)' has invalid percent-encoding: \(reason)"
        }
    }
}
