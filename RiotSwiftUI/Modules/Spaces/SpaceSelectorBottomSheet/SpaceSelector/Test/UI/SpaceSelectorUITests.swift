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
import RiotSwiftUI

class SpaceSelectorUITests: MockScreenTestCase {
    
    func testInitialDisplay() {
        app.goToScreenWithIdentifier(MockSpaceSelectorScreenState.initialList.title)
        
        let disclosureButtons = app.buttons.matching(identifier: "disclosureButton").allElementsBoundByIndex
        XCTAssertEqual(disclosureButtons.count, MockSpaceSelectorService.defaultSpaceList.filter { $0.hasSubItems }.count)

        let notificationBadges = app.staticTexts.matching(identifier: "notificationBadge").allElementsBoundByIndex
        let itemsWithNotifications = MockSpaceSelectorService.defaultSpaceList.filter { $0.notificationCount > 0 || !$0.isJoined }
        XCTAssertEqual(notificationBadges.count, itemsWithNotifications.count)
        for (index, notificationBadge) in notificationBadges.enumerated() {
            let item = itemsWithNotifications[index]
            if item.isJoined {
                XCTAssertEqual("\(item.notificationCount)", notificationBadge.label)
            } else {
                XCTAssertEqual("! ", notificationBadge.label)
            }
        }
        
        let spaceItemNameList = app.staticTexts.matching(identifier: "itemName").allElementsBoundByIndex
        XCTAssertEqual(spaceItemNameList.count, MockSpaceSelectorService.defaultSpaceList.count)
        for (index, item) in MockSpaceSelectorService.defaultSpaceList.enumerated() {
            XCTAssertEqual(item.displayName, spaceItemNameList[index].label)
        }
        
        checkIfEmptyPlaceholder(exists: false)
    }
    
    func testEmptyList() {
        app.goToScreenWithIdentifier(MockSpaceSelectorScreenState.emptyList.title)
        
        let disclosureButtons = app.buttons.matching(identifier: "disclosureButton").allElementsBoundByIndex
        XCTAssertEqual(disclosureButtons.count, 0)
        let notificationBadges = app.staticTexts.matching(identifier: "notificationBadge").allElementsBoundByIndex
        XCTAssertEqual(notificationBadges.count, 0)
        let spaceItemNameList = app.staticTexts.matching(identifier: "itemName").allElementsBoundByIndex
        XCTAssertEqual(spaceItemNameList.count, 0)
        checkIfEmptyPlaceholder(exists: true)
    }
    
    // MARK: - Private methods
    
    private func checkIfEmptyPlaceholder(exists: Bool) {
        XCTAssertEqual(app.staticTexts["emptyListPlaceholderTitle"].exists, exists)
        XCTAssertEqual(app.staticTexts["emptyListPlaceholderMessage"].exists, exists)
        XCTAssertEqual(app.buttons["createSpaceButton"].exists, exists)
    }

}
