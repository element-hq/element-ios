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
