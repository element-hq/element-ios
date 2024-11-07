/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

@objc final class ReactionsMenuViewModel: NSObject, ReactionsMenuViewModelType {
    
    // MARK: - Properties
    
    private let reactions = ["👍", "👎", "😄", "🎉", "😕", "❤️", "🚀", "👀"]
    private var currentViewDatas: [ReactionMenuItemViewData] = []
    
    // MARK: Private
    
    private let aggregatedReactions: MXAggregatedReactions?
    private let reactionsViewData: [ReactionMenuItemViewData] = []
    private let eventId: String
    
    // MARK: Public
    
    @objc weak var coordinatorDelegate: ReactionsMenuViewModelCoordinatorDelegate?
    weak var viewDelegate: ReactionsMenuViewModelViewDelegate?
    
    // MARK: - Setup
    
    @objc init(aggregatedReactions: MXAggregatedReactions?,
               eventId: String) {
        self.aggregatedReactions = aggregatedReactions
        self.eventId = eventId
    }
    
    // MARK: - Public
    
    func process(viewAction: ReactionsMenuViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .tap(let reaction):
            if let viewData = self.currentViewDatas.first(where: { $0.emoji == reaction }) {
                if viewData.isSelected {
                    self.coordinatorDelegate?.reactionsMenuViewModel(self, didRemoveReaction: reaction, forEventId: self.eventId)
                } else {
                    self.coordinatorDelegate?.reactionsMenuViewModel(self, didAddReaction: reaction, forEventId: self.eventId)
                }
            }
        case .moreReactions:
            self.coordinatorDelegate?.reactionsMenuViewModelDidTapMoreReactions(self, forEventId: self.eventId)
        }
    }
    
    // MARK: - Private
    
    private func loadData() {
        let reactionCounts = self.aggregatedReactions?.withNonZeroCount()?.reactions ?? []
        
        var quickReactionsWithUserReactedFlag: [String: Bool] = Dictionary(uniqueKeysWithValues: self.reactions.map { ($0, false) })
        
        reactionCounts.forEach { (reactionCount) in
            if let hasUserReacted = quickReactionsWithUserReactedFlag[reactionCount.reaction], hasUserReacted == false {
                quickReactionsWithUserReactedFlag[reactionCount.reaction] = reactionCount.myUserHasReacted
            }
        }
        
        let reactionMenuItemViewDatas: [ReactionMenuItemViewData] = self.reactions.map { reaction -> ReactionMenuItemViewData in
            let isSelected = quickReactionsWithUserReactedFlag[reaction] ?? false
            return ReactionMenuItemViewData(emoji: reaction, isSelected: isSelected)
        }
        
        self.currentViewDatas = reactionMenuItemViewDatas
        
        self.viewDelegate?.reactionsMenuViewModel(self, didUpdateViewState: ReactionsMenuViewState.loaded(reactionsViewData: reactionMenuItemViewDatas))
    }
}
