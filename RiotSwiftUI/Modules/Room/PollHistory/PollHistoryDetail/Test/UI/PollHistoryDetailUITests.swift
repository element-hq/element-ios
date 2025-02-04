//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

class PollHistoryDetailUITests: MockScreenTestCase {
    func testPollHistoryDetailOpenPoll() {
        app.goToScreenWithIdentifier(MockPollHistoryDetailScreenState.openDisclosed.title)
        let title = app.navigationBars.staticTexts.firstMatch.label
        XCTAssertEqual(title, VectorL10n.pollHistoryActiveSegmentTitle)
        XCTAssertEqual(app.staticTexts["PollHistoryDetail.date"].label, "1/1/01")
        XCTAssertEqual(app.buttons["PollHistoryDetail.viewInTimeLineButton"].label, VectorL10n.pollHistoryDetailViewInTimeline)
    }
    
    func testPollHistoryDetailClosedPoll() {
        app.goToScreenWithIdentifier(MockPollHistoryDetailScreenState.closedDisclosed.title)
        let title = app.navigationBars.staticTexts.firstMatch.label
        XCTAssertEqual(title, VectorL10n.pollHistoryPastSegmentTitle)
        XCTAssertEqual(app.staticTexts["PollHistoryDetail.date"].label, "1/1/01")
        XCTAssertEqual(app.buttons["PollHistoryDetail.viewInTimeLineButton"].label, VectorL10n.pollHistoryDetailViewInTimeline)
    }
}
