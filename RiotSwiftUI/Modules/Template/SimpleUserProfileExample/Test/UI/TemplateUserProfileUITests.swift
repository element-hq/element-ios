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

class TemplateUserProfileUITests: MockScreenTestCase {
    func testTemplateUserProfilePresenceIdle() {
        let presence = TemplateUserProfilePresence.idle
        app.goToScreenWithIdentifier(MockTemplateUserProfileScreenState.presence(presence).title)
        
        let presenceText = app.staticTexts["presenceText"]
        XCTAssert(presenceText.exists)
        XCTAssertEqual(presenceText.label, presence.title)
    }
    
    func testTemplateUserProfilePresenceOffline() {
        let presence = TemplateUserProfilePresence.offline
        app.goToScreenWithIdentifier(MockTemplateUserProfileScreenState.presence(presence).title)
        
        let presenceText = app.staticTexts["presenceText"]
        XCTAssert(presenceText.exists)
        XCTAssertEqual(presenceText.label, presence.title)
    }
    
    func testTemplateUserProfilePresenceOnline() {
        let presence = TemplateUserProfilePresence.online
        app.goToScreenWithIdentifier(MockTemplateUserProfileScreenState.presence(presence).title)
        
        let presenceText = app.staticTexts["presenceText"]
        XCTAssert(presenceText.exists)
        XCTAssertEqual(presenceText.label, presence.title)
    }

    func testTemplateUserProfileLongName() {
        let name = "Somebody with a super long name we would like to test"
        app.goToScreenWithIdentifier(MockTemplateUserProfileScreenState.longDisplayName(name).title)
        
        let displayNameText = app.staticTexts["displayNameText"]
        XCTAssert(displayNameText.exists)
        XCTAssertEqual(displayNameText.label, name)
    }

}
