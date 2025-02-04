//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// A logger for logging to `print`.
///
/// For use with UILog.
class PrintLogger: LoggerProtocol {
    static func verbose(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line, context: Any? = nil) {
        print(message())
    }

    static func debug(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line, context: Any? = nil) {
        print(message())
    }

    static func info(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line, context: Any? = nil) {
        print(message())
    }

    static func warning(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line, context: Any? = nil) {
        print(message())
    }

    static func error(_ message: @autoclosure () -> StaticString, _ file: String = #file, _ function: String = #function, line: Int = #line, context: Any? = nil) {
        print(message())
    }
}
