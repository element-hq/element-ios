// 
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import Element

class VerificationRequiredBannerCheckerTests: XCTestCase {
    private let checker = VerificationRequiredBannerChecker()
    
    func testCanShowBanner() {
        XCTAssertTrue(checker.canShowBanner(for: makeSession(userID: "@user:example.com")))
        XCTAssertTrue(checker.canShowBanner(for: makeSession(userID: "@user:matrix.org")))
    }
    
    private func makeSession(userID: String) -> MXSession! {
        MXSession(matrixRestClient: .init(credentials: .init(homeServer: "",
                                                             userId: userID,
                                                             accessToken: "")))
    }
}
