//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import RiotSwiftUI

class PollHistoryDetailViewModelTests: XCTestCase {
    private enum Constants {
        static let counterInitialValue = 0
    }
    
    var viewModel: PollHistoryDetailViewModel!
    var context: PollHistoryDetailViewModelType.Context!
    
    override func setUpWithError() throws {
        let answerOptions = [TimelinePollAnswerOption(id: "1", text: "1", count: 1, winner: false, selected: false),
                             TimelinePollAnswerOption(id: "2", text: "2", count: 1, winner: false, selected: false),
                             TimelinePollAnswerOption(id: "3", text: "3", count: 1, winner: false, selected: false)]
        
        let timelinePoll = TimelinePollDetails(id: "poll-id",
                                               question: "Question",
                                               answerOptions: answerOptions,
                                               closed: false,
                                               startDate: .init(),
                                               totalAnswerCount: 3,
                                               type: .disclosed,
                                               eventType: .started,
                                               maxAllowedSelections: 1,
                                               hasBeenEdited: false,
                                               hasDecryptionError: false)
        
        viewModel = PollHistoryDetailViewModel(poll: timelinePoll)
        context = viewModel.context
    }

    func testInitialState() {
        XCTAssertFalse(context.viewState.isPollClosed)
    }

    func testProcessAction() {
        viewModel.completion = { result in
            XCTAssertEqual(result, .viewInTimeline)
        }
        viewModel.process(viewAction: .viewInTimeline)
    }

    func testProcessDismiss() {
        viewModel.completion = { result in
            XCTAssertEqual(result, .dismiss)
        }
        viewModel.process(viewAction: .dismiss)
    }
}
