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
import Combine

@testable import RiotSwiftUI

class TimelinePollViewModelTests: XCTestCase {
    var viewModel: TimelinePollViewModel!
    var context: TimelinePollViewModelType.Context!
    var cancellables = Set<AnyCancellable>()
    
    override func setUpWithError() throws {
        let answerOptions = [TimelinePollAnswerOption(id: "1", text: "1", count: 1, winner: false, selected: false),
                             TimelinePollAnswerOption(id: "2", text: "2", count: 1, winner: false, selected: false),
                             TimelinePollAnswerOption(id: "3", text: "3", count: 1, winner: false, selected: false)]
        
        let timelinePoll = TimelinePollDetails(question: "Question",
                                               answerOptions: answerOptions,
                                               closed: false,
                                               totalAnswerCount: 3,
                                               type: .disclosed,
                                               maxAllowedSelections: 1,
                                               hasBeenEdited: false)
        
        viewModel = TimelinePollViewModel(timelinePollDetails: timelinePoll)
        context = viewModel.context
    }
    
    func testInitialState() {
        XCTAssertEqual(context.viewState.poll.answerOptions.count, 3)
        XCTAssertFalse(context.viewState.poll.closed)
        XCTAssertEqual(context.viewState.poll.type, .disclosed)
    }
    
    func testSingleSelectionOnMax1Allowed() {
        context.send(viewAction: .selectAnswerOptionWithIdentifier("1"))
        
        XCTAssertTrue(context.viewState.poll.answerOptions[0].selected)
        XCTAssertFalse(context.viewState.poll.answerOptions[1].selected)
        XCTAssertFalse(context.viewState.poll.answerOptions[2].selected)
    }
    
    func testSingleReselectionOnMax1Allowed() {
        context.send(viewAction: .selectAnswerOptionWithIdentifier("1"))
        context.send(viewAction: .selectAnswerOptionWithIdentifier("1"))
        
        XCTAssertTrue(context.viewState.poll.answerOptions[0].selected)
        XCTAssertFalse(context.viewState.poll.answerOptions[1].selected)
        XCTAssertFalse(context.viewState.poll.answerOptions[2].selected)
    }
    
    func testMultipleSelectionOnMax1Allowed() {
        context.send(viewAction: .selectAnswerOptionWithIdentifier("1"))
        context.send(viewAction: .selectAnswerOptionWithIdentifier("3"))
        
        XCTAssertFalse(context.viewState.poll.answerOptions[0].selected)
        XCTAssertFalse(context.viewState.poll.answerOptions[1].selected)
        XCTAssertTrue(context.viewState.poll.answerOptions[2].selected)
    }
    
    func testMultipleReselectionOnMax1Allowed() {
        context.send(viewAction: .selectAnswerOptionWithIdentifier("1"))
        context.send(viewAction: .selectAnswerOptionWithIdentifier("3"))
        context.send(viewAction: .selectAnswerOptionWithIdentifier("3"))
        
        XCTAssertFalse(context.viewState.poll.answerOptions[0].selected)
        XCTAssertFalse(context.viewState.poll.answerOptions[1].selected)
        XCTAssertTrue(context.viewState.poll.answerOptions[2].selected)
    }

    func testClosedSelection() {
        viewModel.state.poll.closed = true

        context.send(viewAction: .selectAnswerOptionWithIdentifier("1"))
        context.send(viewAction: .selectAnswerOptionWithIdentifier("3"))
        
        XCTAssertFalse(context.viewState.poll.answerOptions[0].selected)
        XCTAssertFalse(context.viewState.poll.answerOptions[1].selected)
        XCTAssertFalse(context.viewState.poll.answerOptions[2].selected)
    }

    func testSingleSelectionOnMax2Allowed() {
        viewModel.state.poll.maxAllowedSelections = 2
        
        context.send(viewAction: .selectAnswerOptionWithIdentifier("1"))
        
        XCTAssertTrue(context.viewState.poll.answerOptions[0].selected)
        XCTAssertFalse(context.viewState.poll.answerOptions[1].selected)
        XCTAssertFalse(context.viewState.poll.answerOptions[2].selected)
    }
    
    func testSingleReselectionOnMax2Allowed() {
        viewModel.state.poll.maxAllowedSelections = 2
        
        context.send(viewAction: .selectAnswerOptionWithIdentifier("1"))
        context.send(viewAction: .selectAnswerOptionWithIdentifier("1"))
        
        XCTAssertFalse(context.viewState.poll.answerOptions[0].selected)
        XCTAssertFalse(context.viewState.poll.answerOptions[1].selected)
        XCTAssertFalse(context.viewState.poll.answerOptions[2].selected)
    }
    
    func testMultipleSelectionOnMax2Allowed() {
        viewModel.state.poll.maxAllowedSelections = 2
        
        context.send(viewAction: .selectAnswerOptionWithIdentifier("1"))
        context.send(viewAction: .selectAnswerOptionWithIdentifier("3"))
        context.send(viewAction: .selectAnswerOptionWithIdentifier("2"))
        
        XCTAssertTrue(context.viewState.poll.answerOptions[0].selected)
        XCTAssertFalse(context.viewState.poll.answerOptions[1].selected)
        XCTAssertTrue(context.viewState.poll.answerOptions[2].selected)
        
        context.send(viewAction: .selectAnswerOptionWithIdentifier("1"))
        
        XCTAssertFalse(context.viewState.poll.answerOptions[0].selected)
        XCTAssertFalse(context.viewState.poll.answerOptions[1].selected)
        XCTAssertTrue(context.viewState.poll.answerOptions[2].selected)
        
        context.send(viewAction: .selectAnswerOptionWithIdentifier("2"))
        
        XCTAssertFalse(context.viewState.poll.answerOptions[0].selected)
        XCTAssertTrue(context.viewState.poll.answerOptions[1].selected)
        XCTAssertTrue(context.viewState.poll.answerOptions[2].selected)
        
        context.send(viewAction: .selectAnswerOptionWithIdentifier("3"))
        
        XCTAssertFalse(context.viewState.poll.answerOptions[0].selected)
        XCTAssertTrue(context.viewState.poll.answerOptions[1].selected)
        XCTAssertFalse(context.viewState.poll.answerOptions[2].selected)
    }
}
