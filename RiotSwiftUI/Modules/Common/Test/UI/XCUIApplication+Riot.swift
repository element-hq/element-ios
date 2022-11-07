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
import XCTest

extension XCUIApplication {
    func goToScreenWithIdentifier(_ identifier: String) {
        // Search for the screen identifier
        let textField = textFields["searchQueryTextField"]
        let button = buttons[identifier]
        
        // Sometimes the search gets stuck without showing any results. Try to nudge it along
        for _ in 0...10 {
            textField.clearAndTypeText(identifier)
            if button.exists {
                break
            }
        }
        
        button.tap()
    }
}

private extension XCUIElement {
    func clearAndTypeText(_ text: String) {
        guard let stringValue = value as? String else {
            XCTFail("Tried to clear and type text into a non string value")
            return
        }

        tap()

        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)

        typeText(deleteString)
        typeText(text)
    }
}
