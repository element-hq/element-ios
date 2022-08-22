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

/// A logger protocol that enables conforming types to be used with UILog.
protocol LoggerProtocol {
    static func verbose(_ message: @autoclosure () -> Any, _ file: String, _ function: String, line: Int, context: Any?)
    static func debug(_ message: @autoclosure () -> Any, _ file: String, _ function: String, line: Int, context: Any?)
    static func info(_ message: @autoclosure () -> Any, _ file: String, _ function: String, line: Int, context: Any?)
    static func warning(_ message: @autoclosure () -> Any, _ file: String, _ function: String, line: Int, context: Any?)
    static func error(_ message: @autoclosure () -> StaticString, _ file: String, _ function: String, line: Int, context: Any?)
}
