//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

final class PollHistoryUITests: MockScreenTestCase {
    func testActivePollHistoryHasContent() {
        app.goToScreenWithIdentifier(MockPollHistoryScreenState.active.title)
        let title = app.navigationBars.firstMatch.identifier
        let emptyText = app.staticTexts["PollHistory.emptyText"]
        let items = app.staticTexts["PollListItem.title"]
        let selectedSegment = app.buttons[VectorL10n.pollHistoryActiveSegmentTitle]
        let loadMoreButton = app.buttons["PollHistory.loadMore"]
        let winningOption = app.staticTexts["PollListData.winningOption"]
        
        XCTAssertEqual(title, VectorL10n.pollHistoryTitle)
        XCTAssertTrue(items.exists)
        XCTAssertFalse(emptyText.exists)
        XCTAssertTrue(selectedSegment.exists)
        XCTAssertEqual(selectedSegment.value as? String, VectorL10n.accessibilitySelected)
        XCTAssertTrue(loadMoreButton.exists)
        XCTAssertFalse(winningOption.exists)
    }
    
    func testPastPollHistoryHasContent() {
        app.goToScreenWithIdentifier(MockPollHistoryScreenState.past.title)
        let title = app.navigationBars.firstMatch.identifier
        let emptyText = app.staticTexts["PollHistory.emptyText"]
        let items = app.staticTexts["PollListItem.title"]
        let selectedSegment = app.buttons[VectorL10n.pollHistoryPastSegmentTitle]
        let loadMoreButton = app.buttons["PollHistory.loadMore"]
        let winningOption = app.buttons["PollAnswerOption0"]
        
        XCTAssertEqual(title, VectorL10n.pollHistoryTitle)
        XCTAssertTrue(items.exists)
        XCTAssertFalse(emptyText.exists)
        XCTAssertTrue(selectedSegment.exists)
        XCTAssertEqual(selectedSegment.value as? String, VectorL10n.accessibilitySelected)
        XCTAssertTrue(loadMoreButton.exists)
        XCTAssertTrue(winningOption.exists)
    }
    
    func testActivePollHistoryHasContentAndCantLoadMore() {
        app.goToScreenWithIdentifier(MockPollHistoryScreenState.activeNoMoreContent.title)
        let emptyText = app.staticTexts["PollHistory.emptyText"]
        let items = app.staticTexts["PollListItem.title"]
        let loadMoreButton = app.buttons["PollHistory.loadMore"]
        
        XCTAssertTrue(items.exists)
        XCTAssertFalse(emptyText.exists)
        XCTAssertFalse(loadMoreButton.exists)
    }
    
    func testActivePollHistoryHasContentAndCanLoadMore() {
        app.goToScreenWithIdentifier(MockPollHistoryScreenState.contentLoading.title)
        let title = app.navigationBars.firstMatch.identifier
        let emptyText = app.staticTexts["PollHistory.emptyText"]
        let items = app.staticTexts["PollListItem.title"]
        let loadMoreButton = app.buttons["PollHistory.loadMore"]
        
        XCTAssertTrue(items.exists)
        XCTAssertFalse(emptyText.exists)
        XCTAssertTrue(loadMoreButton.exists)
        XCTAssertFalse(loadMoreButton.isEnabled)
    }
    
    func testActivePollHistoryEmptyAndCanLoadMore() {
        app.goToScreenWithIdentifier(MockPollHistoryScreenState.empty.title)
        let emptyText = app.staticTexts["PollHistory.emptyText"]
        let items = app.staticTexts["PollListItem.title"]
        let loadMoreButton = app.buttons["PollHistory.loadMore"]
        
        XCTAssertFalse(items.exists)
        XCTAssertTrue(emptyText.exists)
        XCTAssertTrue(loadMoreButton.exists)
        XCTAssertTrue(loadMoreButton.isEnabled)
    }
    
    func testActivePollHistoryEmptyAndLoading() {
        app.goToScreenWithIdentifier(MockPollHistoryScreenState.emptyLoading.title)
        let emptyText = app.staticTexts["PollHistory.emptyText"]
        let items = app.staticTexts["PollListItem.title"]
        let loadMoreButton = app.buttons["PollHistory.loadMore"]
        
        XCTAssertFalse(items.exists)
        XCTAssertTrue(emptyText.exists)
        XCTAssertTrue(loadMoreButton.exists)
        XCTAssertFalse(loadMoreButton.isEnabled)
    }
    
    func testActivePollHistoryEmptyAndCantLoadMore() {
        app.goToScreenWithIdentifier(MockPollHistoryScreenState.emptyNoMoreContent.title)
        let emptyText = app.staticTexts["PollHistory.emptyText"]
        let items = app.staticTexts["PollListItem.title"]
        let loadMoreButton = app.buttons["PollHistory.loadMore"]
        
        XCTAssertFalse(items.exists)
        XCTAssertTrue(emptyText.exists)
        XCTAssertFalse(loadMoreButton.exists)
    }
}
