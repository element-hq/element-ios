//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
