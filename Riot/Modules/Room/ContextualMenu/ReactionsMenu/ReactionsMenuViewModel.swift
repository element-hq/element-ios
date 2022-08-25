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
            loadData()
        case .tap(let reaction):
            if let viewData = currentViewDatas.first(where: { $0.emoji == reaction }) {
                if viewData.isSelected {
                    coordinatorDelegate?.reactionsMenuViewModel(self, didRemoveReaction: reaction, forEventId: eventId)
                } else {
                    coordinatorDelegate?.reactionsMenuViewModel(self, didAddReaction: reaction, forEventId: eventId)
                }
            }
        case .moreReactions:
            coordinatorDelegate?.reactionsMenuViewModelDidTapMoreReactions(self, forEventId: eventId)
        }
    }
    
    // MARK: - Private
    
    private func loadData() {
        let reactionCounts = aggregatedReactions?.withNonZeroCount()?.reactions ?? []
        
        var quickReactionsWithUserReactedFlag: [String: Bool] = Dictionary(uniqueKeysWithValues: reactions.map { ($0, false) })
        
        reactionCounts.forEach { reactionCount in
            if let hasUserReacted = quickReactionsWithUserReactedFlag[reactionCount.reaction], hasUserReacted == false {
                quickReactionsWithUserReactedFlag[reactionCount.reaction] = reactionCount.myUserHasReacted
            }
        }
        
        let reactionMenuItemViewDatas: [ReactionMenuItemViewData] = reactions.map { reaction -> ReactionMenuItemViewData in
            let isSelected = quickReactionsWithUserReactedFlag[reaction] ?? false
            return ReactionMenuItemViewData(emoji: reaction, isSelected: isSelected)
        }
        
        currentViewDatas = reactionMenuItemViewDatas
        
        viewDelegate?.reactionsMenuViewModel(self, didUpdateViewState: ReactionsMenuViewState.loaded(reactionsViewData: reactionMenuItemViewDatas))
    }
}
