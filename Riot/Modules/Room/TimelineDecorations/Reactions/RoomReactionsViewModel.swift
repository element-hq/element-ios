/*
 Copyright 2019 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation

@objc final class RoomReactionsViewModel: NSObject, RoomReactionsViewModelType {
    // MARK: - Constants

    private enum Constants {
        static let maxItemsWhenLimited = 8
    }

    // MARK: - Properties
    
    // MARK: Private
    
    private let aggregatedReactions: MXAggregatedReactions
    private let eventId: String
    private let showAll: Bool
    
    // MARK: Public
    
    @objc weak var viewModelDelegate: RoomReactionsViewModelDelegate?
    weak var viewDelegate: RoomReactionsViewModelViewDelegate?
    
    // MARK: - Setup
    
    @objc init(aggregatedReactions: MXAggregatedReactions,
               eventId: String,
               showAll: Bool) {
        self.aggregatedReactions = aggregatedReactions
        self.eventId = eventId
        self.showAll = showAll
    }
    
    // MARK: - Public
    
    func process(viewAction: RoomReactionsViewAction) {
        switch viewAction {
        case .loadData:
            loadData()
        case .tapReaction(let index):
            guard index < aggregatedReactions.reactions.count else {
                return
            }
            let reactionCount = aggregatedReactions.reactions[index]
            if reactionCount.myUserHasReacted {
                viewModelDelegate?.roomReactionsViewModel(self, didRemoveReaction: reactionCount, forEventId: eventId)
            } else {
                viewModelDelegate?.roomReactionsViewModel(self, didAddReaction: reactionCount, forEventId: eventId)
            }
        case .addNewReaction:
            break
        case .tapShowAction(.showAll):
            viewModelDelegate?.roomReactionsViewModel(self, didShowAllTappedForEventId: eventId)
        case .tapShowAction(.showLess):
            viewModelDelegate?.roomReactionsViewModel(self, didShowLessTappedForEventId: eventId)
        case .tapShowAction(.addReaction):
            viewModelDelegate?.roomReactionsViewModel(self, didTapAddReactionForEventId: eventId)
        case .longPress:
            viewModelDelegate?.roomReactionsViewModel(self, didLongPressForEventId: eventId)
        }
    }

    func loadData() {
        var reactions = aggregatedReactions.reactions
            .map { reactionCount -> RoomReactionViewData in
                RoomReactionViewData(emoji: reactionCount.reaction, countString: "\(reactionCount.count)", isCurrentUserReacted: reactionCount.myUserHasReacted)
            }
        var remainingReactions: [RoomReactionViewData] = []
        var showAllButtonState: RoomReactionsViewState.ShowAllButtonState = .none

        // Limit displayed reactions if required
        if reactions.count > Constants.maxItemsWhenLimited {
            if showAll == true {
                showAllButtonState = .showLess
            } else {
                remainingReactions = Array(reactions[Constants.maxItemsWhenLimited..<reactions.count])
                reactions = Array(reactions[0..<Constants.maxItemsWhenLimited])
                showAllButtonState = .showAll
            }
        }

        viewDelegate?.roomReactionsViewModel(self, didUpdateViewState: .loaded(reactionsViewData: reactions, remainingViewData: remainingReactions, showAllButtonState: showAllButtonState, showAddReaction: reactions.count > 0))
    }
        
    // MARK: - Hashable
    
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(aggregatedReactions)
        hasher.combine(eventId)
        hasher.combine(showAll)
        return hasher.finalize()
    }
}
