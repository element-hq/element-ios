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
        let winningOption = app.staticTexts["PollListData.winningOption"]
        
        XCTAssertEqual(title, VectorL10n.pollHistoryTitle)
        XCTAssertTrue(items.exists)
        XCTAssertFalse(emptyText.exists)
        XCTAssertTrue(selectedSegment.exists)
        XCTAssertEqual(selectedSegment.value as? String, VectorL10n.accessibilitySelected)
        XCTAssertFalse(winningOption.exists)
    }
    
    func testPastPollHistoryHasContent() {
        app.goToScreenWithIdentifier(MockPollHistoryScreenState.past.title)
        let title = app.navigationBars.firstMatch.identifier
        let emptyText = app.staticTexts["PollHistory.emptyText"]
        let items = app.staticTexts["PollListItem.title"]
        let selectedSegment = app.buttons[VectorL10n.pollHistoryPastSegmentTitle]
        let winningOption = app.buttons["PollAnswerOption0"]
        
        XCTAssertEqual(title, VectorL10n.pollHistoryTitle)
        XCTAssertTrue(items.exists)
        XCTAssertFalse(emptyText.exists)
        XCTAssertTrue(selectedSegment.exists)
        XCTAssertEqual(selectedSegment.value as? String, VectorL10n.accessibilitySelected)
        XCTAssertTrue(winningOption.exists)
    }
    
    func testPastPollHistoryIsEmpty() {
        app.goToScreenWithIdentifier(MockPollHistoryScreenState.pastEmpty.title)
        let title = app.navigationBars.firstMatch.identifier
        let emptyText = app.staticTexts["PollHistory.emptyText"]
        let items = app.staticTexts["PollListItem.title"]
        let selectedSegment = app.buttons[VectorL10n.pollHistoryPastSegmentTitle]
        let winningOption = app.staticTexts["PollListData.winningOption"]
        
        XCTAssertEqual(title, VectorL10n.pollHistoryTitle)
        XCTAssertFalse(items.exists)
        XCTAssertTrue(emptyText.exists)
        XCTAssertTrue(selectedSegment.exists)
        XCTAssertEqual(selectedSegment.value as? String, VectorL10n.accessibilitySelected)
        XCTAssertFalse(winningOption.exists)
    }
    
    func testLoaderIsShowing() {
        app.goToScreenWithIdentifier(MockPollHistoryScreenState.loading.title)
        let title = app.navigationBars.firstMatch.identifier
        let loadingText = app.staticTexts["PollHistory.loadingText"]
        let items = app.staticTexts["PollListItem.title"]
        
        XCTAssertEqual(title, VectorL10n.pollHistoryTitle)
        XCTAssertFalse(items.exists)
        XCTAssertTrue(loadingText.exists)
    }
}
