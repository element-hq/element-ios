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

import XCTest
import RiotSwiftUI

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
