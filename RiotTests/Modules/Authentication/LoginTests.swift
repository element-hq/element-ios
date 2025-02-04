// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import Element

class LoginTests: XCTestCase {
    func testUserParameterIdentifier() {
        // Given a user identifier.
        let id = LoginPasswordParameters.Identifier.user("test")
        
        // When converting it to a dictionary.
        let dictionary = id.dictionary
        
        // Then the dictionary should have the expected format.
        XCTAssertEqual(dictionary["type"], "m.id.user")
        XCTAssertEqual(dictionary["user"], "test")
    }
    
    func testPhoneParameterIdentifier() {
        // Given a phone number identifier.
        let id = LoginPasswordParameters.Identifier.phone(country: "44", phone: "7777")
        
        // When converting it to a dictionary.
        let dictionary = id.dictionary
        
        // Then the dictionary should have the expected format.
        XCTAssertEqual(dictionary["type"], "m.id.phone")
        XCTAssertEqual(dictionary["country"], "44")
        XCTAssertEqual(dictionary["phone"], "7777")
    }
    
    func testEmailParameterIdentifier() {
        // Given an email identifier.
        let id = LoginPasswordParameters.Identifier.thirdParty(medium: .email, address: "test@example.com")
        
        // When converting it to a dictionary.
        let dictionary = id.dictionary
        
        // Then the dictionary should have the expected format.
        XCTAssertEqual(dictionary["type"], "m.id.thirdparty")
        XCTAssertEqual(dictionary["medium"], "email")
        XCTAssertEqual(dictionary["address"], "test@example.com")
    }
    
    func testMSISDNParameterIdentifier() {
        // Given an msisdn phone number identifier.
        let id = LoginPasswordParameters.Identifier.thirdParty(medium: .msisdn, address: "123456789")
        
        // When converting it to a dictionary.
        let dictionary = id.dictionary
        
        // Then the dictionary should have the expected format.
        XCTAssertEqual(dictionary["type"], "m.id.thirdparty")
        XCTAssertEqual(dictionary["medium"], "msisdn")
        XCTAssertEqual(dictionary["address"], "123456789")
    }
}
