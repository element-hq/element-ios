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

import UIKit

@objc final class ReactionsMenuViewModel: NSObject, ReactionsMenuViewModelType {

    // MARK: - Properties

    // MARK: Private
    private let aggregations: MXAggregations
    private let roomId: String
    private let eventId: String

    // MARK: Public

    private(set) var isAgreeButtonSelected: Bool = false
    private(set) var isDisagreeButtonSelected: Bool = false
    private(set) var isLikeButtonSelected: Bool = false
    private(set) var isDislikeButtonSelected: Bool = false

    weak var viewDelegate: ReactionsMenuViewModelDelegate?
    @objc weak var coordinatorDelegate: ReactionsMenuViewModelCoordinatorDelegate?

    // MARK: - Setup

    @objc init(aggregations: MXAggregations, roomId: String, eventId: String) {
        self.aggregations = aggregations
        self.roomId = roomId
        self.eventId = eventId
        
        super.init()

        self.loadData()
        self.listenToDataUpdate()
    }

    // MARK: - Public

    func process(viewAction: ReactionsMenuViewAction) {
        var reaction: ReactionsMenuReaction?
        var newState: Bool?

        switch viewAction {
        case .toggleReaction(let menuReaction):
            reaction = menuReaction

            switch menuReaction {
            case .agree:
                newState = !self.isAgreeButtonSelected
            case .disagree:
                newState = !self.isDisagreeButtonSelected
            case .like:
                newState = !self.isLikeButtonSelected
            case .dislike:
                newState = !self.isDislikeButtonSelected
            }
        }

        guard let theReaction = reaction, let theNewState = newState else {
            return
        }

        self.react(withReaction: theReaction, selected: theNewState)
    }

    // MARK: - Private

    private func resetData() {
        self.isAgreeButtonSelected = false
        self.isDisagreeButtonSelected = false
        self.isLikeButtonSelected = false
        self.isDislikeButtonSelected = false
    }

    private func loadData() {
        guard let reactionCounts = self.aggregations.aggregatedReactions(onEvent: self.eventId, inRoom: self.roomId)?.withNonZeroCount()?.reactions else {
            return
        }

        self.resetData()
        reactionCounts.forEach { (reactionCount) in
            if reactionCount.myUserHasReacted {
                if let reaction = ReactionsMenuReaction(rawValue: reactionCount.reaction) {
                    switch reaction {
                    case .agree:
                        self.isAgreeButtonSelected = true
                    case .disagree:
                        self.isDisagreeButtonSelected = true
                    case .like:
                        self.isLikeButtonSelected = true
                    case .dislike:
                        self.isDislikeButtonSelected = true
                    }
                }
            }
        }

        self.viewDelegate?.reactionsMenuViewModelDidUpdate(self)
    }

    private func listenToDataUpdate() {
        self.aggregations.listenToReactionCountUpdate(inRoom: self.roomId) { [weak self] (changes) in

            guard let sself = self else {
                return
            }

            if changes[sself.eventId] != nil {
                sself.loadData()
            }
        }
    }
    
    private func react(withReaction reaction: ReactionsMenuReaction, selected: Bool) {
        
        // If required, unreact first
        if selected {
            self.ensure3StateButtons(withReaction: reaction)
        }
        
        let reactionString = reaction.rawValue
        
        if selected {
            self.coordinatorDelegate?.reactionsMenuViewModel(self, didAddReaction: reactionString, forEventId: self.eventId)
        } else {
            self.coordinatorDelegate?.reactionsMenuViewModel(self, didRemoveReaction: reactionString, forEventId: self.eventId)
        }
    }

    // We can like, dislike, be indifferent but we cannot like & dislike at the same time
    private func ensure3StateButtons(withReaction reaction: ReactionsMenuReaction) {
        var unreaction: ReactionsMenuReaction?

        switch reaction {
        case .agree:
            if isDisagreeButtonSelected {
                unreaction = .disagree
            }
        case .disagree:
            if isAgreeButtonSelected {
                unreaction = .agree
            }
        case .like:
            if isDislikeButtonSelected {
                unreaction = .dislike
            }
        case .dislike:
            if isLikeButtonSelected {
                unreaction = .like
            }
        }

        if let unreaction = unreaction {
            self.react(withReaction: unreaction, selected: false)
        }
    }
}
