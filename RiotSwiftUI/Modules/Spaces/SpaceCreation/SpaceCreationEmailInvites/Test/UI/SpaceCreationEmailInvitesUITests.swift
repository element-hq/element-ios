// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationEmailInvites SpaceCreationEmailInvites
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

class SpaceCreationEmailInvitesUITests: MockScreenTestCase {
    func testDefaultEmailValues() {
        app.goToScreenWithIdentifier(MockSpaceCreationEmailInvitesScreenState.defaultEmailValues.title)
        
        let emailTextFieldsCount = app.textFields.matching(identifier: "emailTextField").count
        XCTAssertEqual(emailTextFieldsCount, 2)
    }
    
    func testEmailEntered() {
        app.goToScreenWithIdentifier(MockSpaceCreationEmailInvitesScreenState.emailEntered.title)
        
        let emailTextFieldsCount = app.textFields.matching(identifier: "emailTextField").count
        XCTAssertEqual(emailTextFieldsCount, 2)
    }
    
    func testEmailValidationFailed() {
        app.goToScreenWithIdentifier(MockSpaceCreationEmailInvitesScreenState.emailValidationFailed.title)
        
        let emailTextFieldsCount = app.textFields.matching(identifier: "emailTextField").count
        XCTAssertEqual(emailTextFieldsCount, 2)
    }
    
    func testLoading() {
        app.goToScreenWithIdentifier(MockSpaceCreationEmailInvitesScreenState.loading.title)
        
        let emailTextFieldsCount = app.textFields.matching(identifier: "emailTextField").count
        XCTAssertEqual(emailTextFieldsCount, 2)
    }
}
