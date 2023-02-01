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
