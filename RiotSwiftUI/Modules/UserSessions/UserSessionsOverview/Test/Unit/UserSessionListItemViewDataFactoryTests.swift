//
// Copyright 2022 New Vector Ltd
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

import Combine
import XCTest

@testable import RiotSwiftUI

class UserSessionListItemViewDataFactoryTests: XCTestCase {
    let factory = UserSessionListItemViewDataFactory()
    
    func testSessionDetailsWithTimestamp() {
        // Given other devices in each of the verification states.
        let sessionInfoVerified = UserSessionInfo.mockPhone(verificationState: .verified)
        let sessionInfoUnverified = UserSessionInfo.mockPhone(verificationState: .unverified)
        let sessionInfoUnknown = UserSessionInfo.mockPhone(verificationState: .unknown)
        
        // When getting session details for each of them.
        let sessionDetailsVerified = factory.create(from: sessionInfoVerified).sessionDetails
        let sessionDetailsUnverified = factory.create(from: sessionInfoUnverified).sessionDetails
        let sessionDetailsUnknown = factory.create(from: sessionInfoUnknown).sessionDetails
        
        // Then the details should be formatted correctly.
        let lastActivityString = UserSessionLastActivityFormatter.lastActivityDateString(from: sessionInfoVerified.lastSeenTimestamp!)
        XCTAssertEqual(sessionDetailsVerified,
                       VectorL10n.userSessionItemDetails(VectorL10n.userSessionVerifiedShort, VectorL10n.userSessionItemDetailsLastActivity(lastActivityString)),
                       "The details should show as verified with a last activity string when verified.")
        XCTAssertEqual(sessionDetailsUnverified,
                       VectorL10n.userSessionItemDetails(VectorL10n.userSessionUnverifiedShort, VectorL10n.userSessionItemDetailsLastActivity(lastActivityString)),
                       "The details should show as unverified with a last activity string when unverified.")
        XCTAssertEqual(sessionDetailsUnknown,
                       VectorL10n.userSessionItemDetailsLastActivity(lastActivityString),
                       "The details should only show the last activity string when verification is unknown.")
    }
    
    func testSessionDetailsVerifiedWithoutTimestamp() {
        // Given a verified other device
        let sessionInfoVerified = UserSessionInfo.mockPhone(hasTimestamp: false)
        let sessionInfoUnverified = UserSessionInfo.mockPhone(verificationState: .unverified, hasTimestamp: false)
        let sessionInfoUnknown = UserSessionInfo.mockPhone(verificationState: .unknown, hasTimestamp: false)
        
        // When getting session details
        let sessionDetailsVerified = factory.create(from: sessionInfoVerified).sessionDetails
        let sessionDetailsUnverified = factory.create(from: sessionInfoUnverified).sessionDetails
        let sessionDetailsUnknown = factory.create(from: sessionInfoUnknown).sessionDetails
        
        // Then the details should contain the verification state and a last seen date.
        XCTAssertEqual(sessionDetailsVerified, VectorL10n.userSessionVerifiedShort,
                       "The details should only show the verification state when no timestamp exists.")
        XCTAssertEqual(sessionDetailsUnverified, VectorL10n.userSessionUnverifiedShort,
                       "The details should only show the verification state when no timestamp exists.")
        XCTAssertEqual(sessionDetailsUnknown, VectorL10n.userSessionVerificationUnknownShort,
                       "The details should only show the verification state when no timestamp exists.")
    }
}
