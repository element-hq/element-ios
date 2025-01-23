//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

class TemplateSimpleScreenUITests: MockScreenTestCase {
    func testTemplateSimpleScreenPromptRegular() {
        let promptType = TemplateSimpleScreenPromptType.regular
        app.goToScreenWithIdentifier(MockTemplateSimpleScreenScreenState.promptType(promptType).title)
        
        let title = app.staticTexts["title"]
        XCTAssert(title.exists)
        XCTAssertEqual(title.label, promptType.title)
    }
    
    func testTemplateSimpleScreenPromptUpgrade() {
        let promptType = TemplateSimpleScreenPromptType.upgrade
        app.goToScreenWithIdentifier(MockTemplateSimpleScreenScreenState.promptType(promptType).title)
        
        let title = app.staticTexts["title"]
        XCTAssert(title.exists)
        XCTAssertEqual(title.label, promptType.title)
    }
}
