// File created from ScreenTemplate
// $ createScreen.sh toto EmojiPicker
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

final class EmojiPickerViewModel: EmojiPickerViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let roomId: String
    private let eventId: String
    private let emojiService: EmojiServiceType
    private let emojiStore: EmojiStore
    private let processingQueue: DispatchQueue
    
    private lazy var aggregatedReactionsByEmoji: [String: MXReactionCount] = {
        return self.buildAggregatedReactionsByEmoji()
    }()
    
    // MARK: Public

    weak var viewDelegate: EmojiPickerViewModelViewDelegate?
    weak var coordinatorDelegate: EmojiPickerViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, roomId: String, eventId: String) {
        self.session = session
        self.roomId = roomId
        self.eventId = eventId
        self.emojiService = EmojiMartService()
        self.emojiStore = EmojiStore.shared
        self.processingQueue = DispatchQueue(label: "\(type(of: self))")
    }
    
    // MARK: - Public
    
    func process(viewAction: EmojiPickerViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .tap(emojiItemViewData: let emojiItemViewData):
            let emoji = emojiItemViewData.emoji
            
            if emojiItemViewData.isSelected {
                self.coordinatorDelegate?.emojiPickerViewModel(self, didRemoveEmoji: emoji, forEventId: self.eventId)
            } else {
                self.coordinatorDelegate?.emojiPickerViewModel(self, didAddEmoji: emoji, forEventId: self.eventId)
            }
        case .search(text: let searchText):
            self.searchEmojis(with: searchText)
        case .cancel:
            self.coordinatorDelegate?.emojiPickerViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func loadData() {
        if self.emojiStore.getAll().isEmpty == false {
            let emojiCategories = self.emojiStore.getAll()
            let emojiCatagoryViewDataList = self.emojiCatagoryViewDataList(from: emojiCategories)
            self.update(viewState: .loaded(emojiCategories: emojiCatagoryViewDataList))
        } else {
            self.update(viewState: .loading)
            self.emojiService.getEmojiCategories { response in
                switch response {
                case .success(let emojiCategories):
                    
                    self.emojiStore.set(emojiCategories)
                    
                    let emojiCatagoryViewDataList = self.emojiCatagoryViewDataList(from: emojiCategories)
                    self.update(viewState: .loaded(emojiCategories: emojiCatagoryViewDataList))
                case .failure(let error):
                    self.update(viewState: .error(error))
                }
            }
        }
    }
    
    private func searchEmojis(with searchText: String?) {
        self.processingQueue.async {
            let filteredEmojiCategories: [EmojiCategory]
            
            if let searchText = searchText, searchText.isEmpty == false {
                filteredEmojiCategories = self.emojiStore.findEmojiItemsSortedByCategory(with: searchText)
            } else {
                filteredEmojiCategories = self.emojiStore.getAll()
            }
            
            let emojiCatagoryViewDataList = self.emojiCatagoryViewDataList(from: filteredEmojiCategories)
            
            DispatchQueue.main.async {
                self.update(viewState: .loaded(emojiCategories: emojiCatagoryViewDataList))
            }
        }
    }
    
    private func update(viewState: EmojiPickerViewState) {
        self.viewDelegate?.emojiPickerViewModel(self, didUpdateViewState: viewState)
    }
        
    private func emojiCatagoryViewDataList(from emojiCategories: [EmojiCategory]) -> [EmojiPickerCategoryViewData] {
        return emojiCategories.map { (emojiCategory) -> EmojiPickerCategoryViewData in
            let emojiPickerViewDataList = emojiCategory.emojis.map({ (emojiItem) -> EmojiPickerItemViewData in
                let isSelected = self.isUserReacted(with: emojiItem.value)
                return EmojiPickerItemViewData(identifier: emojiItem.shortName, emoji: emojiItem.value, isSelected: isSelected)
            })
            return EmojiPickerCategoryViewData(identifier: emojiCategory.identifier, name: emojiCategory.name, emojiViewDataList: emojiPickerViewDataList)
        }
    }
    
    private func isUserReacted(with emoji: String) -> Bool {
        guard let reactionCount = self.aggregatedReactionsByEmoji[emoji] else {
            return false
        }
        return reactionCount.myUserHasReacted
    }
    
    private func buildAggregatedReactionsByEmoji() -> [String: MXReactionCount] {
        guard let aggregatedReactions = self.session.aggregations.aggregatedReactions(onEvent: self.eventId, inRoom: self.roomId) else {
            return [:]
        }
        
        let initial: [String: MXReactionCount] = [:]
        
        return aggregatedReactions.reactions.reduce(into: initial) { (aggregatedReactionsByEmoji, reactionCount) in
            aggregatedReactionsByEmoji[reactionCount.reaction] = reactionCount
        }
    }
}
