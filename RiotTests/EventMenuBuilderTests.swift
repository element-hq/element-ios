// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest
import UIKit
@testable import Element

class EventMenuBuilderTests: XCTestCase {
    
    func testSorting() {
        let builder = EventMenuBuilder()
        
        let title2 = "Title 2"
        
        builder.addItem(withType: .copy,
                        action: UIAlertAction(title: "Title 1", style: .default, handler: nil))
        
        builder.addItem(withType: .viewInRoom,
                        action: UIAlertAction(title: title2, style: .default, handler: nil))
        
        let actions = builder.build()
        
        XCTAssertEqual(actions.first?.title, title2, "Item with title 'title2' must come first in the result")
    }
    
    func testEmptiness() {
        let builder = EventMenuBuilder()
        
        XCTAssertTrue(builder.isEmpty, "Builder must be empty after initialization")
        
        builder.addItem(withType: .cancel,
                        action: UIAlertAction(title: "Cancel", style: .default, handler: nil))
        
        XCTAssertTrue(builder.isEmpty, "Builder must still be empty after adding only a cancel action")
        
        builder.addItem(withType: .share,
                        action: UIAlertAction(title: "some_title", style: .default, handler: nil))
        
        XCTAssertFalse(builder.isEmpty, "Builder must not be empty after adding an item")
        
        builder.reset()
        
        XCTAssertTrue(builder.isEmpty, "Builder must be empty again after reset")
    }
    
}
