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
class UserSuggestionService: UserSuggestionServiceProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let room: MXRoom
    
    private var suggestionItems: [UserSuggestionItemProtocol] = []
    
    // MARK: Public
    
    var items: CurrentValueSubject<[UserSuggestionItemProtocol], Never>
    
    // MARK: - Setup
    
    init(room: MXRoom) {
        self.room = room
        self.items = CurrentValueSubject([])
        
        generateUsersWithCount(10)
        items.send(suggestionItems)
    }
    
    func processPartialUserName(_ userName: String) {
        guard userName.count > 0 else {
            items.send(suggestionItems)
            return
        }
        
        items.send(suggestionItems.filter({ userSuggestion in
            return (userSuggestion.displayName?.lowercased().range(of: userName.lowercased()) != .none)
        }))
    }
    
    private func generateUsersWithCount(_ count: UInt) {
        suggestionItems.removeAll()
        for _ in 0..<count {
            let identifier = "@" + UUID().uuidString
            suggestionItems.append(MockUserSuggestionServiceItem(userId: identifier, displayName: identifier, avatarUrl: "mxc://matrix.org/VyNYAgahaiAzUoOeZETtQ"))
        }
    }
}
