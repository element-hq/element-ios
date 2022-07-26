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

class AnalyticsPromptUITests: MockScreenTestCase {
    /// Verify that the prompt is displayed correctly for new users.
    func testAnalyticsPromptNewUser() {
        app.goToScreenWithIdentifier(MockAnalyticsPromptScreenState.promptType(.newUser).title)
        
        let enableButton = app.buttons["enableButton"]
        let disableButton = app.buttons["disableButton"]
        
        XCTAssert(enableButton.exists)
        XCTAssert(disableButton.exists)
        
        XCTAssertEqual(enableButton.label, VectorL10n.enable)
        XCTAssertEqual(disableButton.label, VectorL10n.locationSharingInvalidAuthorizationNotNow)
    }
    
    /// Verify that the prompt is displayed correctly for when upgrading from Matomo.
    func testAnalyticsPromptUpgrade() {
        app.goToScreenWithIdentifier(MockAnalyticsPromptScreenState.promptType(.upgrade).title)
        
        let enableButton = app.buttons["enableButton"]
        let disableButton = app.buttons["disableButton"]
        
        XCTAssert(enableButton.exists)
        XCTAssert(disableButton.exists)
        
        XCTAssertEqual(enableButton.label, VectorL10n.analyticsPromptYes)
        XCTAssertEqual(disableButton.label, VectorL10n.analyticsPromptStop)
    }
}
