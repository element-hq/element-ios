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
class AnalyticsPromptUITests: MockScreenTest {

    override class var screenType: MockScreenState.Type {
        return MockAnalyticsPromptScreenState.self
    }

    override class func createTest() -> MockScreenTest {
        return AnalyticsPromptUITests(selector: #selector(verifyAnalyticsPromptScreen))
    }

    func verifyAnalyticsPromptScreen() throws {
        guard let screenState = screenState as? MockAnalyticsPromptScreenState else { fatalError("no screen") }
        switch screenState {
        case .promptType(let promptType):
            verifyAnalyticsPromptType(promptType)
        }
    }
    
    /// Verify that the prompt is displayed correctly for new users compared to upgrading from Matomo
    func verifyAnalyticsPromptType(_ promptType: AnalyticsPromptType) {
        let enableButton = app.buttons["enableButton"]
        let disableButton = app.buttons["disableButton"]
        
        XCTAssert(enableButton.exists)
        XCTAssert(disableButton.exists)
        
        switch promptType {
        case .newUser:
            XCTAssertEqual(enableButton.label, VectorL10n.enable)
            XCTAssertEqual(disableButton.label, VectorL10n.locationSharingInvalidAuthorizationNotNow)
        case .upgrade:
            XCTAssertEqual(enableButton.label, VectorL10n.analyticsPromptYes)
            XCTAssertEqual(disableButton.label, VectorL10n.analyticsPromptStop)
        }
    }

    func verifyAnalyticsPromptLongName(name: String) {
        let displayNameText = app.staticTexts["displayNameText"]
        XCTAssert(displayNameText.exists)
        XCTAssertEqual(displayNameText.label, name)
    }

}
