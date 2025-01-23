//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// A logger protocol that enables conforming types to be used with UILog.
protocol LoggerProtocol {
    static func verbose(_ message: @autoclosure () -> Any, _ file: String, _ function: String, line: Int, context: Any?)
    static func debug(_ message: @autoclosure () -> Any, _ file: String, _ function: String, line: Int, context: Any?)
    static func info(_ message: @autoclosure () -> Any, _ file: String, _ function: String, line: Int, context: Any?)
    static func warning(_ message: @autoclosure () -> Any, _ file: String, _ function: String, line: Int, context: Any?)
    static func error(_ message: @autoclosure () -> StaticString, _ file: String, _ function: String, line: Int, context: Any?)
}
