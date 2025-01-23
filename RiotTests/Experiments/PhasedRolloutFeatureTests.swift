// 
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import XCTest
@testable import Element

class PhasedRolloutFeatureTests: XCTestCase {
    
    private func randomUserId() -> String {
        return "user_" + UUID().uuidString.prefix(6)
    }
    
    func test_allDisabled() {
        let feature = PhasedRolloutFeature(name: "disabled", targetPercentage: 0)
        for _ in 0 ..< 1000 {
            let isEnabled = feature.isEnabled(userId: randomUserId())
            XCTAssertFalse(isEnabled)
        }
    }
    
    func test_allEnabled() {
        let feature = PhasedRolloutFeature(name: "enabled", targetPercentage: 1)
        for _ in 0 ..< 1000 {
            let isEnabled = feature.isEnabled(userId: randomUserId())
            XCTAssertTrue(isEnabled)
        }
    }
    
    func test_someEnabled() {
        let feature = PhasedRolloutFeature(name: "some", targetPercentage: 0.5)
        var statuses = Set<Bool>()
        for _ in 0 ..< 1000 {
            let isEnabled = feature.isEnabled(userId: randomUserId())
            statuses.insert(isEnabled)
        }
        
        // We test by checking that we encountered both enabled and disabled cases
        XCTAssertTrue(statuses.contains(true))
        XCTAssertTrue(statuses.contains(false))
    }
}
