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

@objc final class BubbleReactionsViewModel: NSObject, BubbleReactionsViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let aggregatedReactions: MXAggregatedReactions
    private let reactionsViewData: [BubbleReactionViewData]
    private let eventId: String
    
    // MARK: Public
    
    @objc weak var viewModelDelegate: BubbleReactionsViewModelDelegate?
    weak var viewDelegate: BubbleReactionsViewModelViewDelegate?
    
    // MARK: - Setup
    
    @objc init(aggregatedReactions: MXAggregatedReactions,
               eventId: String) {
        self.aggregatedReactions = aggregatedReactions
        self.eventId = eventId
        
        self.reactionsViewData = aggregatedReactions.reactions.map { (reactionCount) -> BubbleReactionViewData in
            return BubbleReactionViewData(emoji: reactionCount.reaction, countString: "\(reactionCount.count)", isCurrentUserReacted: reactionCount.myUserHasReacted)
        }
    }
    
    // MARK: - Public
    
    func process(viewAction: BubbleReactionsViewAction) {
        switch viewAction {
        case .loadData:
            self.viewDelegate?.bubbleReactionsViewModel(self, didUpdateViewState: .loaded(reactionsViewData: self.reactionsViewData))
        case .tapReaction(let index):
            guard index < self.aggregatedReactions.reactions.count else {
                return
            }
            let reactionCount = self.aggregatedReactions.reactions[index]
            if reactionCount.myUserHasReacted {
                self.viewModelDelegate?.bubbleReactionsViewModel(self, didRemoveReaction: reactionCount, forEventId: self.eventId)
            } else {
                self.viewModelDelegate?.bubbleReactionsViewModel(self, didAddReaction: reactionCount, forEventId: self.eventId)
            }
        case .addNewReaction:
            break
        }
    }
}
