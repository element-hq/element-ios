// 
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import XCTest
@testable import Element

class ExperimentTests: XCTestCase {
    
    private func randomUserId() -> String {
        return "user_" + UUID().uuidString.prefix(6)
    }
    
    func test_singleVariant() {
        let experiment = Experiment(name: "single", variants: 1)
        for _ in 0 ..< 1000 {
            let variant = experiment.variant(userId: randomUserId())
            XCTAssertEqual(variant, 0)
        }
    }
    
    func test_twoVariants() {
        let experiment = Experiment(name: "two", variants: 2)
        
        var variants = Set<UInt>()
        for _ in 0 ..< 1000 {
            let variant = experiment.variant(userId: randomUserId())
            variants.insert(variant)
        }
        
        // We perform the test by collecting all assigned variants for 1000 users
        // and ensuring we only encounter variants 0 and 1
        XCTAssertEqual(variants.count, 2)
        XCTAssertTrue(variants.contains(0))
        XCTAssertTrue(variants.contains(1))
        XCTAssertFalse(variants.contains(2))
    }
    
    func test_manyVariants() {
        let experiment = Experiment(name: "many", variants: 5)
        
        var variants = Set<UInt>()
        for _ in 0 ..< 10000 {
            let variant = experiment.variant(userId: randomUserId())
            variants.insert(variant)
        }
        
        // We perform the test by collecting all assigned variants for 10000 users
        // and ensuring we only encounter variants between 0 and 4
        XCTAssertTrue(variants.count >= 2 && variants.count <= 5)
        XCTAssertTrue(variants.isSubset(of: .init([0, 1, 2, 3, 4])))
        XCTAssertFalse(variants.contains(5))
    }
}
