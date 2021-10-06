// File created from SimpleUserProfileExample
// $ createScreen.sh Room/UserSuggestion UserSuggestion
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

import Foundation
import Combine

@available(iOS 14.0, *)
struct RoomMembersProviderMember {
    var identifier: String
    var displayName: String
    var avatarURL: String
}

@available(iOS 14.0, *)
protocol RoomMembersProviderProtocol {
    func fetchMembers(_ members: @escaping ([RoomMembersProviderMember]) -> Void)
}

@available(iOS 14.0, *)
struct UserSuggestionServiceItem: UserSuggestionItemProtocol {
    let userId: String
    let displayName: String?
    let avatarUrl: String?
}

@available(iOS 14.0, *)
class UserSuggestionService: UserSuggestionServiceProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let roomMembersProvider: RoomMembersProviderProtocol
    
    private var suggestionItems: [UserSuggestionItemProtocol] = []
    
    // MARK: Public
    
    var items: CurrentValueSubject<[UserSuggestionItemProtocol], Never>
    var currentTextTrigger: String?
    
    // MARK: - Setup
    
    init(roomMembersProvider: RoomMembersProviderProtocol) {
        self.roomMembersProvider = roomMembersProvider
        self.items = CurrentValueSubject([])
    }
    
    // MARK: - UserSuggestionServiceProtocol
    
    func processTextMessage(_ textMessage: String) {
        roomMembersProvider.fetchMembers { [weak self] members in
            guard let self = self else {
                return
            }
            
            self.suggestionItems = members.map { member in
                UserSuggestionServiceItem(userId: member.identifier, displayName: member.displayName, avatarUrl: member.avatarURL)
            }
            
            self.items.send([])
            self.currentTextTrigger = nil
            
            guard textMessage.count > 0 else {
                return
            }
            
            let components = textMessage.components(separatedBy: .whitespaces)
            
            guard let lastComponent = components.last else {
                return
            }
            
            // Partial username should start with one and only one "@" character
            guard lastComponent.prefix(while: { character in character == "@" }).count == 1 else {
                return
            }
            
            self.currentTextTrigger = lastComponent
            
            var partialName = lastComponent
            partialName.removeFirst()
            
            self.items.send(self.suggestionItems.filter({ userSuggestion in
                let containedInUsername = userSuggestion.userId.lowercased().range(of: partialName.lowercased()) != .none
                let containedInDisplayName = (userSuggestion.displayName ?? "").lowercased().range(of: partialName.lowercased()) != .none
                
                return (containedInUsername || containedInDisplayName)
            }))
        }
    }
}
