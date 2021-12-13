// File created from SimpleUserProfileExample
// $ createScreen.sh Room/PollTimeline PollTimeline
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

import SwiftUI
import Combine

@available(iOS 14, *)
typealias PollTimelineViewModelType = StateStoreViewModel<PollTimelineViewState,
                                                          PollTimelineStateAction,
                                                          PollTimelineViewAction>
@available(iOS 14, *)
class PollTimelineViewModel: PollTimelineViewModelType {
    
    // MARK: - Properties

    // MARK: Private
    
    // MARK: Public
    
    var callback: PollTimelineViewModelCallback?
    
    // MARK: - Setup
    
    init(timelinePoll: TimelinePoll) {
        super.init(initialViewState: PollTimelineViewState(poll: timelinePoll, bindings: PollTimelineViewStateBindings()))
    }
    
    // MARK: - Public
    
    override func process(viewAction: PollTimelineViewAction) {
        switch viewAction {
        case .selectAnswerOptionWithIdentifier(_):
            dispatch(action: .viewAction(viewAction, callback))
        }
    }
    
    override class func reducer(state: inout PollTimelineViewState, action: PollTimelineStateAction) {
        switch action {
        case .viewAction(let viewAction, let callback):
            switch viewAction {
            
            // Update local state. An update will be pushed from the coordinator once sent.
            case .selectAnswerOptionWithIdentifier(let identifier):
                guard !state.poll.closed else {
                    return
                }
                
                if (state.poll.maxAllowedSelections == 1) {
                    updateSingleSelectPollLocalState(&state, selectedAnswerIdentifier: identifier, callback: callback)
                } else {
                    updateMultiSelectPollLocalState(&state, selectedAnswerIdentifier: identifier, callback: callback)
                }
            }
        case .updateWithPoll(let poll):
            state.poll = poll
        case .showAnsweringFailure:
            state.bindings.showsAnsweringFailureAlert = true
        case .showClosingFailure:
            state.bindings.showsClosingFailureAlert = true
        }
    }
    
    // MARK: - Private
    
    static func updateSingleSelectPollLocalState(_ state: inout PollTimelineViewState, selectedAnswerIdentifier: String, callback: PollTimelineViewModelCallback?) {
        for answerOption in state.poll.answerOptions {
            if answerOption.selected {
                answerOption.selected = false
                
                if(answerOption.count > 0) {
                    answerOption.count = answerOption.count - 1
                    state.poll.totalAnswerCount -= 1
                }
            }
            
            if answerOption.id == selectedAnswerIdentifier {
                answerOption.selected = true
                answerOption.count += 1
                state.poll.totalAnswerCount += 1
            }
        }
        
        informCoordinatorOfSelectionUpdate(state: state, callback: callback)
    }
    
    static func updateMultiSelectPollLocalState(_ state: inout PollTimelineViewState, selectedAnswerIdentifier: String, callback: PollTimelineViewModelCallback?) {
        let selectedAnswerOptions = state.poll.answerOptions.filter { $0.selected == true }
        
        let isDeselecting = selectedAnswerOptions.filter { $0.id == selectedAnswerIdentifier }.count > 0
        
        if !isDeselecting && selectedAnswerOptions.count >= state.poll.maxAllowedSelections {
            return
        }
        
        for answerOption in state.poll.answerOptions where answerOption.id == selectedAnswerIdentifier {
            if answerOption.selected {
                answerOption.selected = false
                answerOption.count -= 1
                state.poll.totalAnswerCount -= 1
            } else {
                answerOption.selected = true
                answerOption.count += 1
                state.poll.totalAnswerCount += 1
            }
        }
        
        informCoordinatorOfSelectionUpdate(state: state, callback: callback)
    }
    
    static func informCoordinatorOfSelectionUpdate(state: PollTimelineViewState, callback: PollTimelineViewModelCallback?) {
        let selectedIdentifiers = state.poll.answerOptions.compactMap { answerOption in
            answerOption.selected ? answerOption.id : nil
        }
        
        callback?(.selectedAnswerOptionsWithIdentifiers(selectedIdentifiers))
    }
}
