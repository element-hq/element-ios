// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
    
    static func verbose(
        _ message: @autoclosure () -> Any,
        _ file: String = #file,
        _ function: String = #function,
        line: Int = #line,
        context: Any? = nil) {
        _logger?.verbose(message(), file, function, line: line, context: context)
    }
    
    static func debug(
        _ message: @autoclosure () -> Any,
        _ file: String = #file,
        _ function: String = #function,
        line: Int = #line,
        context: Any? = nil) {
        _logger?.debug(message(), file, function, line: line, context: context)
    }
    
    static func info(
        _ message: @autoclosure () -> Any,
        _ file: String = #file,
        _ function: String = #function,
        line: Int = #line,
        context: Any? = nil) {
        _logger?.info(message(), file, function, line: line, context: context)
    }
    
    static func warning(
        _ message: @autoclosure () -> Any,
        _ file: String = #file,
        _ function: String = #function,
        line: Int = #line,
        context: Any? = nil) {
        _logger?.warning(message(), file, function, line: line, context: context)
    }
    
    static func error(
        _ message: @autoclosure () -> StaticString,
        _ file: String = #file,
        _ function: String = #function,
        line: Int = #line,
        context: Any? = nil) {
        _logger?.error(message(), file, function, line: line, context: context)
    }
}
