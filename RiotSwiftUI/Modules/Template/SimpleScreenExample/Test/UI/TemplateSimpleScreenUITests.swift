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

@available(iOS 14.0, *)
class TemplateSimpleScreenUITests: MockScreenTest {

    override class var screenType: MockScreenState.Type {
        return MockTemplateSimpleScreenScreenState.self
    }

    override class func createTest() -> MockScreenTest {
        return TemplateSimpleScreenUITests(selector: #selector(verifyTemplateSimpleScreenScreen))
    }

    func verifyTemplateSimpleScreenScreen() throws {
        guard let screenState = screenState as? MockTemplateSimpleScreenScreenState else { fatalError("no screen") }
        switch screenState {
        case .promptType(let promptType):
            verifyTemplateSimpleScreenPromptType(promptType: promptType)
        }
    }
    
    func verifyTemplateSimpleScreenPromptType(promptType: TemplateSimpleScreenPromptType) {
        let title = app.staticTexts["title"]
        XCTAssert(title.exists)
        XCTAssertEqual(title.label, promptType.title)
    }

}
