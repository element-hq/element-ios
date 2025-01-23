// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationEmailInvites SpaceCreationEmailInvites
//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

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
