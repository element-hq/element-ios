//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import XCTest

extension XCUIApplication {
    func goToScreenWithIdentifier(_ identifier: String, shouldUseSlowTyping: Bool = false) {
        // Search for the screen identifier
        let textField = textFields["searchQueryTextField"]
        let button = buttons[identifier]
        
        // This always fixes the stuck search issue, but makes the typing slower
        if shouldUseSlowTyping {
            textField.typeSlowly(identifier)
        } else {
            // Sometimes the search gets stuck without showing any results. Try to nudge it along
            for _ in 0...10 {
                textField.clearAndTypeText(identifier)
                if button.exists {
                    break
                }
            }
        }
        
        button.tap()
    }
}

extension XCUIElement {
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
    
    func typeSlowly(_ text: String) {
        tap()
        text.forEach{ typeText(String($0)) }
    }
}
