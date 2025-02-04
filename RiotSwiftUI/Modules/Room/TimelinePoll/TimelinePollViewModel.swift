//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
    
    init(timelinePollDetailsState: TimelinePollDetailsState) {
        super.init(initialViewState: TimelinePollViewState(pollState: timelinePollDetailsState, bindings: TimelinePollViewStateBindings()))
    }
    
    // MARK: - Public
    
    override func process(viewAction: TimelinePollViewAction) {
        switch viewAction {
        // Update local state. An update will be pushed from the coordinator once sent.
        case .selectAnswerOptionWithIdentifier(let identifier):
            // only if the poll is ready and not closed
            guard case let .loaded(poll) = state.pollState, !poll.closed else {
                return
            }
            if poll.maxAllowedSelections == 1 {
                updateSingleSelectPollLocalState(selectedAnswerIdentifier: identifier, callback: completion)
            } else {
                updateMultiSelectPollLocalState(&state, selectedAnswerIdentifier: identifier, callback: completion)
            }
        }
    }
    
    // MARK: - TimelinePollViewModelProtocol
    
    func updateWithPollDetailsState(_ pollDetailsState: TimelinePollDetailsState) {
        state.pollState = pollDetailsState
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
        guard case var .loaded(poll) = state.pollState else { return }
        
        var pollAnswerOptions = poll.answerOptions
        pollAnswerOptions.updateEach { answerOption in
            if answerOption.selected {
                answerOption.selected = false
                answerOption.count = UInt(max(0, Int(answerOption.count) - 1))
                poll.totalAnswerCount = UInt(max(0, Int(poll.totalAnswerCount) - 1))
            }
            
            if answerOption.id == selectedAnswerIdentifier {
                answerOption.selected = true
                answerOption.count += 1
                poll.totalAnswerCount += 1
            }
        }
        poll.answerOptions = pollAnswerOptions
        state.pollState = .loaded(poll)
        informCoordinatorOfSelectionUpdate(state: state, callback: callback)
    }
    
    func updateMultiSelectPollLocalState(_ state: inout TimelinePollViewState, selectedAnswerIdentifier: String, callback: TimelinePollViewModelCallback?) {
        guard case .loaded(var poll) = state.pollState else { return }
        
        let selectedAnswerOptions = poll.answerOptions.filter { $0.selected == true }
        
        let isDeselecting = selectedAnswerOptions.filter { $0.id == selectedAnswerIdentifier }.count > 0
        
        if !isDeselecting, selectedAnswerOptions.count >= poll.maxAllowedSelections {
            return
        }
        
        var pollAnswerOptions = poll.answerOptions
        pollAnswerOptions.updateEach { answerOption in
            if answerOption.id != selectedAnswerIdentifier {
                return
            }
            
            if answerOption.selected {
                answerOption.selected = false
                answerOption.count = UInt(max(0, Int(answerOption.count) - 1))
                poll.totalAnswerCount = UInt(max(0, Int(poll.totalAnswerCount) - 1))
            } else {
                answerOption.selected = true
                answerOption.count += 1
                poll.totalAnswerCount += 1
            }
        }
        poll.answerOptions = pollAnswerOptions
        state.pollState = .loaded(poll)
        informCoordinatorOfSelectionUpdate(state: state, callback: callback)
    }
    
    func informCoordinatorOfSelectionUpdate(state: TimelinePollViewState, callback: TimelinePollViewModelCallback?) {
        guard case .loaded(let poll) = state.pollState else { return }
        
        let selectedIdentifiers = poll.answerOptions.compactMap { answerOption in
            answerOption.selected ? answerOption.id : nil
        }
        callback?(.selectedAnswerOptionsWithIdentifiers(selectedIdentifiers))
    }
}
