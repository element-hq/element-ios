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

class UserSessionNameUITests: MockScreenTestCase {
    func testUserSessionNameInitialState() {
        app.goToScreenWithIdentifier(MockUserSessionNameScreenState.initialName.title)
        
        assertButtonsExists()
        let doneButton = app.buttons[VectorL10n.done]
        XCTAssertTrue(doneButton.exists)
        XCTAssertFalse(doneButton.isEnabled)
    }
    
    func testUserSessionNameEmptyState() {
        app.goToScreenWithIdentifier(MockUserSessionNameScreenState.empty.title)
        
        assertButtonsExists()
        let doneButton = app.buttons[VectorL10n.done]
        XCTAssertTrue(doneButton.exists)
        XCTAssertFalse(doneButton.isEnabled)
    }
    
    func testUserSessionNameChangedState() {
        app.goToScreenWithIdentifier(MockUserSessionNameScreenState.changedName.title)
        
        assertButtonsExists()
        let doneButton = app.buttons[VectorL10n.done]
        XCTAssertTrue(doneButton.exists)
        XCTAssertTrue(doneButton.isEnabled)
    }
}

private extension UserSessionNameUITests {
    func assertButtonsExists() {
        let buttons = [VectorL10n.done, VectorL10n.cancel, "LearnMore"]
        
        for buttonId in buttons {
            let button = app.buttons[buttonId]
            XCTAssertTrue(button.exists)
        }
    }
}
