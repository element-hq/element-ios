//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

class SpaceSelectorUITests: MockScreenTestCase {
    func testInitialDisplay() {
        app.goToScreenWithIdentifier(MockSpaceSelectorScreenState.initialList.title)
        
        let disclosureButtons = app.buttons.matching(identifier: "disclosureButton").allElementsBoundByIndex
        XCTAssertEqual(disclosureButtons.count, MockSpaceSelectorService.defaultSpaceList.filter(\.hasSubItems).count)

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
