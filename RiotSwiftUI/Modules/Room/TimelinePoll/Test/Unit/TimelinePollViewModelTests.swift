//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import XCTest

@testable import RiotSwiftUI

class TimelinePollViewModelTests: XCTestCase {
    var viewModel: TimelinePollViewModel!
    var context: TimelinePollViewModelType.Context!
    var cancellables = Set<AnyCancellable>()
    
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
        
        viewModel = TimelinePollViewModel(timelinePollDetailsState: .loaded(timelinePoll))
        context = viewModel.context
    }
    
    func testInitialState() {
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions.count, 3)
        XCTAssertEqual(context.viewState.pollState.poll?.closed, false)
        XCTAssertEqual(context.viewState.pollState.poll?.type, .disclosed)
    }
    
    func testSingleSelectionOnMax1Allowed() {
        context.send(viewAction: .selectAnswerOptionWithIdentifier("1"))
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions[0].selected, true)
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions[1].selected, false)
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions[2].selected, false)
    }
    
    func testSingleReselectionOnMax1Allowed() {
        context.send(viewAction: .selectAnswerOptionWithIdentifier("1"))
        context.send(viewAction: .selectAnswerOptionWithIdentifier("1"))
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions[0].selected, true)
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions[1].selected, false)
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions[2].selected, false)
    }
    
    func testMultipleSelectionOnMax1Allowed() {
        context.send(viewAction: .selectAnswerOptionWithIdentifier("1"))
        context.send(viewAction: .selectAnswerOptionWithIdentifier("3"))
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions[0].selected, false)
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions[1].selected, false)
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions[2].selected, true)
    }
    
    func testMultipleReselectionOnMax1Allowed() {
        context.send(viewAction: .selectAnswerOptionWithIdentifier("1"))
        context.send(viewAction: .selectAnswerOptionWithIdentifier("3"))
        context.send(viewAction: .selectAnswerOptionWithIdentifier("3"))
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions[0].selected, false)
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions[1].selected, false)
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions[2].selected, true)
    }

    func testClosedSelection() {
        guard case var .loaded(poll) = context.viewState.pollState else {
            return XCTFail()
        }
        poll.closed = true
        viewModel.updateWithPollDetailsState(.loaded(poll))

        context.send(viewAction: .selectAnswerOptionWithIdentifier("1"))
        context.send(viewAction: .selectAnswerOptionWithIdentifier("3"))
        
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions[0].selected, false)
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions[1].selected, false)
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions[2].selected, false)
    }

    func testSingleSelectionOnMax2Allowed() {
        guard case var .loaded(poll) = context.viewState.pollState else {
            return XCTFail()
        }
        poll.maxAllowedSelections = 2
        viewModel.updateWithPollDetailsState(.loaded(poll))
        
        context.send(viewAction: .selectAnswerOptionWithIdentifier("1"))
        
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions[0].selected, true)
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions[1].selected, false)
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions[2].selected, false)
    }
    
    func testSingleReselectionOnMax2Allowed() {
        guard case var .loaded(poll) = context.viewState.pollState else {
            return XCTFail()
        }
        poll.maxAllowedSelections = 2
        viewModel.updateWithPollDetailsState(.loaded(poll))
        
        context.send(viewAction: .selectAnswerOptionWithIdentifier("1"))
        context.send(viewAction: .selectAnswerOptionWithIdentifier("1"))
        
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions[0].selected, false)
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions[1].selected, false)
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions[2].selected, false)
    }
    
    func testMultipleSelectionOnMax2Allowed() {
        guard case var .loaded(poll) = context.viewState.pollState else {
            return XCTFail()
        }
        poll.maxAllowedSelections = 2
        viewModel.updateWithPollDetailsState(.loaded(poll))

        context.send(viewAction: .selectAnswerOptionWithIdentifier("1"))
        context.send(viewAction: .selectAnswerOptionWithIdentifier("3"))
        context.send(viewAction: .selectAnswerOptionWithIdentifier("2"))
        
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions[0].selected, true)
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions[1].selected, false)
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions[2].selected, true)
        
        context.send(viewAction: .selectAnswerOptionWithIdentifier("1"))
        
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions[0].selected, false)
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions[1].selected, false)
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions[2].selected, true)
        
        context.send(viewAction: .selectAnswerOptionWithIdentifier("2"))
        
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions[0].selected, false)
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions[1].selected, true)
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions[2].selected, true)
        
        context.send(viewAction: .selectAnswerOptionWithIdentifier("3"))
        
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions[0].selected, false)
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions[1].selected, true)
        XCTAssertEqual(context.viewState.pollState.poll?.answerOptions[2].selected, false)
    }
}

private extension TimelinePollDetailsState {
    var poll: TimelinePollDetails? {
        switch self {
        case .loaded(let poll):
            return poll
        default:
            return nil
        }
    }
}
