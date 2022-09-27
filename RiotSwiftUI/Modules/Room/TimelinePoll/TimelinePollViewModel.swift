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

import Combine
import SwiftUI

typealias TimelinePollViewModelType = StateStoreViewModel<TimelinePollViewState, TimelinePollViewAction>

class TimelinePollViewModel: TimelinePollViewModelType, TimelinePollViewModelProtocol {
    // MARK: - Properties

    // MARK: Private
    
    // MARK: Public
    
    var completion: TimelinePollViewModelCallback?
    
    // MARK: - Setup
    
    init(timelinePollDetails: TimelinePollDetails) {
        super.init(initialViewState: TimelinePollViewState(poll: timelinePollDetails, bindings: TimelinePollViewStateBindings()))
    }
    
    // MARK: - Public
    
    override func process(viewAction: TimelinePollViewAction) {
        switch viewAction {
        // Update local state. An update will be pushed from the coordinator once sent.
        case .selectAnswerOptionWithIdentifier(let identifier):
            guard !state.poll.closed else {
                return
            }
            
            if state.poll.maxAllowedSelections == 1 {
                updateSingleSelectPollLocalState(selectedAnswerIdentifier: identifier, callback: completion)
            } else {
                updateMultiSelectPollLocalState(&state, selectedAnswerIdentifier: identifier, callback: completion)
            }
        }
    }
    
    // MARK: - TimelinePollViewModelProtocol
    
    func updateWithPollDetails(_ pollDetails: TimelinePollDetails) {
        state.poll = pollDetails
    }
    
    func showAnsweringFailure() {
        state.bindings.alertInfo = AlertInfo(id: .failedSubmittingAnswer,
                                             title: VectorL10n.pollTimelineVoteNotRegisteredTitle,
                                             message: VectorL10n.pollTimelineVoteNotRegisteredSubtitle)
    }
    
    func showClosingFailure() {
        state.bindings.alertInfo = AlertInfo(id: .failedClosingPoll,
                                             title: VectorL10n.pollTimelineNotClosedTitle,
                                             message: VectorL10n.pollTimelineNotClosedSubtitle)
    }
        
    // MARK: - Private
    
    func updateSingleSelectPollLocalState(selectedAnswerIdentifier: String, callback: TimelinePollViewModelCallback?) {
        state.poll.answerOptions.updateEach { answerOption in
            if answerOption.selected {
                answerOption.selected = false
                answerOption.count = UInt(max(0, Int(answerOption.count) - 1))
                state.poll.totalAnswerCount = UInt(max(0, Int(state.poll.totalAnswerCount) - 1))
            }
            
            if answerOption.id == selectedAnswerIdentifier {
                answerOption.selected = true
                answerOption.count += 1
                state.poll.totalAnswerCount += 1
            }
        }
        
        informCoordinatorOfSelectionUpdate(state: state, callback: callback)
    }
    
    func updateMultiSelectPollLocalState(_ state: inout TimelinePollViewState, selectedAnswerIdentifier: String, callback: TimelinePollViewModelCallback?) {
        let selectedAnswerOptions = state.poll.answerOptions.filter { $0.selected == true }
        
        let isDeselecting = selectedAnswerOptions.filter { $0.id == selectedAnswerIdentifier }.count > 0
        
        if !isDeselecting, selectedAnswerOptions.count >= state.poll.maxAllowedSelections {
            return
        }
        
        state.poll.answerOptions.updateEach { answerOption in
            if answerOption.id != selectedAnswerIdentifier {
                return
            }
            
            if answerOption.selected {
                answerOption.selected = false
                answerOption.count = UInt(max(0, Int(answerOption.count) - 1))
                state.poll.totalAnswerCount = UInt(max(0, Int(state.poll.totalAnswerCount) - 1))
            } else {
                answerOption.selected = true
                answerOption.count += 1
                state.poll.totalAnswerCount += 1
            }
        }
        
        informCoordinatorOfSelectionUpdate(state: state, callback: callback)
    }
    
    func informCoordinatorOfSelectionUpdate(state: TimelinePollViewState, callback: TimelinePollViewModelCallback?) {
        let selectedIdentifiers = state.poll.answerOptions.compactMap { answerOption in
            answerOption.selected ? answerOption.id : nil
        }
        
        callback?(.selectedAnswerOptionsWithIdentifiers(selectedIdentifiers))
    }
}
