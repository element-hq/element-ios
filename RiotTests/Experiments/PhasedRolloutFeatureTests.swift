// 
// Copyright 2023 New Vector Ltd
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
