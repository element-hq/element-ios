//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// A logger for use in different application targets.
///
/// It can be configured at runtime with a suitable logger.
class UILog: LoggerProtocol {
    static var _logger: LoggerProtocol.Type?
    static func configure(logger: LoggerProtocol.Type) {
        _logger = logger
    }
    
    static func verbose(_ message: @autoclosure () -> Any,
                        _ file: String = #file,
                        _ function: String = #function,
                        line: Int = #line,
                        context: Any? = nil) {
        _logger?.verbose(message(), file, function, line: line, context: context)
    }
    
    static func debug(_ message: @autoclosure () -> Any,
                      _ file: String = #file,
                      _ function: String = #function,
                      line: Int = #line,
                      context: Any? = nil) {
        _logger?.debug(message(), file, function, line: line, context: context)
    }
    
    static func info(_ message: @autoclosure () -> Any,
                     _ file: String = #file,
                     _ function: String = #function,
                     line: Int = #line,
                     context: Any? = nil) {
        _logger?.info(message(), file, function, line: line, context: context)
    }
    
    static func warning(_ message: @autoclosure () -> Any,
                        _ file: String = #file,
                        _ function: String = #function,
                        line: Int = #line,
                        context: Any? = nil) {
        _logger?.warning(message(), file, function, line: line, context: context)
    }
    
    static func error(_ message: @autoclosure () -> StaticString,
                      _ file: String = #file,
                      _ function: String = #function,
                      line: Int = #line,
                      context: Any? = nil) {
        _logger?.error(message(), file, function, line: line, context: context)
    }
}
