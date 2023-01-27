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
