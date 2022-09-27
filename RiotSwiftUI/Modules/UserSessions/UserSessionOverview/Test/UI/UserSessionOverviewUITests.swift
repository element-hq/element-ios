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

import RiotSwiftUI
import XCTest

class UserSessionOverviewUITests: MockScreenTestCase {
    func test_whenCurrentSessionSelected_correctNavTittleDisplayed() {
        app.goToScreenWithIdentifier(MockUserSessionOverviewScreenState.currentSession.title)
        let navTitle = VectorL10n.userSessionOverviewCurrentSessionTitle
        XCTAssertTrue(app.navigationBars[navTitle].staticTexts[navTitle].exists)
    }
    
    func test_whenOtherSessionSelected_correctNavTittleDisplayed() {
        app.goToScreenWithIdentifier(MockUserSessionOverviewScreenState.otherSession.title)
        let navTitle = VectorL10n.userSessionOverviewSessionTitle
        XCTAssertTrue(app.navigationBars[navTitle].staticTexts[navTitle].exists)
    }
    
    func test_whenSessionOverviewPresented_sessionDetailsButtonExists() {
        app.goToScreenWithIdentifier(MockUserSessionOverviewScreenState.currentSession.title)
        XCTAssertTrue(app.buttons[VectorL10n.userSessionOverviewSessionDetailsButtonTitle].exists)
    }
}
