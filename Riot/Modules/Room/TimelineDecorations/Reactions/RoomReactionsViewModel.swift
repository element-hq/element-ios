/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

@objc final class RoomReactionsViewModel: NSObject, RoomReactionsViewModelType {

    // MARK: - Constants

    private enum Constants {
        static let maxItemsWhenLimited: Int = 8
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
            self.loadData()
        case .tapReaction(let index):
            guard index < self.aggregatedReactions.reactions.count else {
                return
            }
            let reactionCount = self.aggregatedReactions.reactions[index]
            if reactionCount.myUserHasReacted {
                self.viewModelDelegate?.roomReactionsViewModel(self, didRemoveReaction: reactionCount, forEventId: self.eventId)
            } else {
                self.viewModelDelegate?.roomReactionsViewModel(self, didAddReaction: reactionCount, forEventId: self.eventId)
            }
        case .addNewReaction:
            break
        case .tapShowAction(.showAll):
            self.viewModelDelegate?.roomReactionsViewModel(self, didShowAllTappedForEventId: self.eventId)
        case .tapShowAction(.showLess):
            self.viewModelDelegate?.roomReactionsViewModel(self, didShowLessTappedForEventId: self.eventId)
        case .tapShowAction(.addReaction):
            self.viewModelDelegate?.roomReactionsViewModel(self, didTapAddReactionForEventId: self.eventId)
        case .longPress:
            self.viewModelDelegate?.roomReactionsViewModel(self, didLongPressForEventId: self.eventId)
        }
    }

    func loadData() {
        var reactions = self.aggregatedReactions.reactions
            .map { (reactionCount) -> RoomReactionViewData in
                RoomReactionViewData(emoji: reactionCount.reaction, countString: "\(reactionCount.count)", isCurrentUserReacted: reactionCount.myUserHasReacted)
            }
        var remainingReactions: [RoomReactionViewData] = []
        var showAllButtonState: RoomReactionsViewState.ShowAllButtonState = .none

        // Limit displayed reactions if required
        if reactions.count > Constants.maxItemsWhenLimited {
            if self.showAll == true {
                showAllButtonState = .showLess
            } else {
                remainingReactions = Array(reactions[Constants.maxItemsWhenLimited..<reactions.count])
                reactions = Array(reactions[0..<Constants.maxItemsWhenLimited])
                showAllButtonState = .showAll
            }
        }

        self.viewDelegate?.roomReactionsViewModel(self, didUpdateViewState: .loaded(reactionsViewData: reactions, remainingViewData: remainingReactions, showAllButtonState: showAllButtonState, showAddReaction: reactions.count > 0))
    }
        
    // MARK: - Hashable
    
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(self.aggregatedReactions)
        hasher.combine(self.eventId)
        hasher.combine(self.showAll)
        return hasher.finalize()
    }
}
