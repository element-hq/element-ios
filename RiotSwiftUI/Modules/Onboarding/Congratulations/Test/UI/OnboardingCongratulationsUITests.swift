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

class OnboardingCongratulationsUITests: MockScreenTestCase {
    func testButtons() {
        app.goToScreenWithIdentifier(MockOnboardingCongratulationsScreenState.regular.title)
        
        let personalizeButton = app.buttons["personalizeButton"]
        XCTAssertTrue(personalizeButton.exists, "The personalization button should be shown.")
        
        let homeButton = app.buttons["homeButton"]
        XCTAssertTrue(homeButton.exists, "The home button should always be shown.")
    }
    
    func testButtonsWhenPersonalizationIsDisabled() {
        app.goToScreenWithIdentifier(MockOnboardingCongratulationsScreenState.personalizationDisabled.title)
        
        let personalizeButton = app.buttons["personalizeButton"]
        XCTAssertFalse(personalizeButton.exists, "The personalization button should be hidden.")
        
        let homeButton = app.buttons["homeButton"]
        XCTAssertTrue(homeButton.exists, "The home button should always be shown.")
    }
}
