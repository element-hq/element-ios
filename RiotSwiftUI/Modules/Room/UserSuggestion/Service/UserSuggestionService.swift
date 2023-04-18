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
import Foundation
import WysiwygComposer

struct RoomMembersProviderMember {
    var userId: String
    var displayName: String
    var avatarUrl: String
}

class UserSuggestionID: NSObject {
    /// A special case added for suggesting `@room` mentions.
    @objc static let room = "@room"
}

protocol RoomMembersProviderProtocol {
    var canMentionRoom: Bool { get }
    func fetchMembers(_ members: @escaping ([RoomMembersProviderMember]) -> Void)
}

struct UserSuggestionServiceItem: UserSuggestionItemProtocol {
    let userId: String
    let displayName: String?
    let avatarUrl: String?
}

class UserSuggestionService: UserSuggestionServiceProtocol {
    // MARK: - Properties
    
    // MARK: Private
    
    private let roomMemberProvider: RoomMembersProviderProtocol
    
    private var suggestionItems: [UserSuggestionItemProtocol] = []
    private let currentTextTriggerSubject = CurrentValueSubject<String?, Never>(nil)
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: Public
    
    var items = CurrentValueSubject<[UserSuggestionItemProtocol], Never>([])
    
    var currentTextTrigger: String? {
        currentTextTriggerSubject.value
    }
    
    // MARK: - Setup
    
    init(roomMemberProvider: RoomMembersProviderProtocol, shouldDebounce: Bool = true) {
        self.roomMemberProvider = roomMemberProvider
        
        if shouldDebounce {
            currentTextTriggerSubject
                .debounce(for: 0.5, scheduler: RunLoop.main)
                .removeDuplicates()
                .sink { [weak self] in self?.fetchAndFilterMembersForTextTrigger($0) }
                .store(in: &cancellables)
        } else {
            currentTextTriggerSubject
                .sink { [weak self] in self?.fetchAndFilterMembersForTextTrigger($0) }
                .store(in: &cancellables)
        }
    }
    
    // MARK: - UserSuggestionServiceProtocol
    
    func processTextMessage(_ textMessage: String?) {
        guard let textMessage = textMessage,
              textMessage.count > 0,
              let lastComponent = textMessage.components(separatedBy: .whitespaces).last,
              lastComponent.prefix(while: { $0 == "@" }).count == 1 // Partial username should start with one and only one "@" character
        else {
            items.send([])
            currentTextTriggerSubject.send(nil)
            return
        }
        
        currentTextTriggerSubject.send(lastComponent)
    }

    func processSuggestionPattern(_ suggestionPattern: SuggestionPattern?) {
        guard let suggestionPattern, suggestionPattern.key == .at else {
            items.send([])
            currentTextTriggerSubject.send(nil)
            return
        }

        currentTextTriggerSubject.send("@" + suggestionPattern.text)
    }
    
    // MARK: - Private
    
    private func fetchAndFilterMembersForTextTrigger(_ textTrigger: String?) {
        guard var partialName = textTrigger else {
            return
        }
        
        partialName.removeFirst() // remove the '@' prefix
        
        roomMemberProvider.fetchMembers { [weak self] members in
            guard let self = self else {
                return
            }
            
            self.suggestionItems = members.withRoom(self.roomMemberProvider.canMentionRoom).map { member in
                UserSuggestionServiceItem(userId: member.userId, displayName: member.displayName, avatarUrl: member.avatarUrl)
            }
            
            self.items.send(self.suggestionItems.filter { userSuggestion in
                let containedInUsername = userSuggestion.userId.lowercased().contains(partialName.lowercased())
                let containedInDisplayName = (userSuggestion.displayName ?? "").lowercased().contains(partialName.lowercased())
                
                return (containedInUsername || containedInDisplayName)
            })
        }
    }
}

extension Array where Element == RoomMembersProviderMember {
    /// Returns the array with an additional member that represents an `@room` mention.
    func withRoom(_ canMentionRoom: Bool) -> Self {
        guard canMentionRoom else { return self }
        return self + [RoomMembersProviderMember(userId: UserSuggestionID.room, displayName: "Everyone", avatarUrl: "")]
    }
}
