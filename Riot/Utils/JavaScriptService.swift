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
import JavaScriptCore

final class JavaScriptService {

    static let shared = JavaScriptService()

    private let context: JSContext? = JSContext()

    private init() {
        guard let context = context else {
            NSLog("[JavaScriptService] Failed to create JSContext")
            return
        }

        context.exceptionHandler = { context, exception in
            NSLog("[JavaScriptService] Caught exception: \(exception?.toString() ?? "-")")
        }
        
        guard
            let url = Bundle.main.url(forResource: "crossplatform", withExtension: "js"),
            let script = try? String(contentsOf: url)
        else {
            NSLog("[JavaScriptService] Failed to load crossplatform.js")
            return
        }

        context.evaluateScript(script)
        context.setObject(MXEvent.self, forKeyedSubscript: "MXEvent" as NSString)
        context.objectForKeyedSubscript("crossplatform").objectForKeyedSubscript("languageHandler")
            .setObject(_t, forKeyedSubscript: "_t" as NSString)
    }
    
    func aggregateAndGenerateSummary(userEvents: [AnyHashable: Any], summaryLength: Int) -> String? {
        context?.objectForKeyedSubscript("crossplatform").objectForKeyedSubscript("memberEvents")
            .objectForKeyedSubscript("aggregateAndGenerateSummary").call(withArguments: [userEvents, summaryLength]).toString()
    }
    
}

// MARK: - MXEvent to MatrixEvent Shim

@objc protocol MXEventJSExports: JSExport {
    
    func getType() -> String
    func getSender() -> String
    func getStateKey() -> String
    func getContent() -> [String: Any]
    func getPrevContent() -> [String: Any]

}

extension MXEvent: MXEventJSExports {

    func getType() -> String {
        return type
    }
    
    func getSender() -> String {
        return sender
    }
    
    func getStateKey() -> String {
        return stateKey
    }
    
    func getContent() -> [String: Any] {
        return content ?? [:]
    }
    
    func getPrevContent() -> [String: Any] {
        return prevContent ?? [:]
    }

}

// MARK: - Translation Shim

private let _t: @convention(block) (String, [String: Any]) -> String = { text, variables in
    // TODO: Load translation for text, handle pluralisation
    variables.reduce(text) { result, item in
        result.replacingOccurrences(of: "%(\(item.key))s", with: "\(item.value)", options: [], range: nil)
    }
}
