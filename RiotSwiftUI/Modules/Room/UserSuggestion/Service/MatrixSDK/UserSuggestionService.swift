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
struct UserSuggestionServiceItem: UserSuggestionItemProtocol {
    let userId: String
    let displayName: String?
    let avatarUrl: String?
}

@available(iOS 14.0, *)
class UserSuggestionService: UserSuggestionServiceProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let room: MXRoom
    
    private var suggestionItems: [UserSuggestionItemProtocol] = []
    private var roomJoinedMembers: [MXRoomMember] = []
    
    // MARK: Public
    
    var items: CurrentValueSubject<[UserSuggestionItemProtocol], Never>
    var currentTextTrigger: String?
    
    // MARK: - Setup
    
    init(room: MXRoom) {
        self.room = room
        self.items = CurrentValueSubject([])
        
        self.room.members { [weak self] members in
            guard let self = self, let joinedMembers = members?.joinedMembers else {
                return
            }
            
            self.roomJoinedMembers = joinedMembers
            
            self.suggestionItems = joinedMembers.map { member in
                UserSuggestionServiceItem(userId: member.userId, displayName: member.displayname, avatarUrl: member.avatarUrl)
            }
        } lazyLoadedMembers: { [weak self] lazyMembers in
            guard let self = self, let joinedMembers = lazyMembers?.joinedMembers else {
                return
            }
            
            self.roomJoinedMembers = joinedMembers
            
            self.suggestionItems = joinedMembers.map { member in
                UserSuggestionServiceItem(userId: member.userId, displayName: member.displayname, avatarUrl: member.avatarUrl)
            }
        } failure: { error in
            MXLog.error("[UserSuggestionService] Failed loading room with error: \(String(describing: error))")
        }
    }
    
    func roomMemberForIdentifier(_ identifier: String) -> MXRoomMember? {
        return roomJoinedMembers.filter { $0.userId == identifier }.first
    }
    
    // MARK: - UserSuggestionServiceProtocol
    
    func processTextMessage(_ textMessage: String) {
        items.send([])
        currentTextTrigger = nil
        
        guard textMessage.count > 0 else {
            return
        }
        
        let components = textMessage.components(separatedBy: .whitespaces)
        
        guard let lastComponent = components.last else {
            return
        }
        
        guard lastComponent.hasPrefix("@") else {
            return
        }
        
        currentTextTrigger = lastComponent
        
        var partialName = lastComponent
        partialName.removeFirst()
        
        items.send(suggestionItems.filter({ userSuggestion in
            let containedInUsername = userSuggestion.userId.lowercased().range(of: partialName.lowercased()) != .none
            let containedInDisplayName = (userSuggestion.displayName ?? "").lowercased().range(of: partialName.lowercased()) != .none
            return (containedInUsername || containedInDisplayName)
        }))
    }
}
