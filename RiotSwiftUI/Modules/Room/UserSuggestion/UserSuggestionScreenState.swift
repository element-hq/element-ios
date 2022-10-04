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
import SwiftUI

enum MockUserSuggestionScreenState: MockScreenState, CaseIterable {
    case multipleResults
    
    private static var members: [RoomMembersProviderMember]!
    
    var screenType: Any.Type {
        UserSuggestionList.self
    }
    
    var screenView: ([Any], AnyView) {
        let service = UserSuggestionService(roomMemberProvider: self)
        let listViewModel = UserSuggestionViewModel(userSuggestionService: service)
        
        let viewModel = UserSuggestionListWithInputViewModel(listViewModel: listViewModel) { textMessage in
            service.processTextMessage(textMessage)
        }
        
        return (
            [service, listViewModel],
            AnyView(UserSuggestionListWithInput(viewModel: viewModel)
                .addDependency(MockAvatarService.example))
        )
    }
}

extension MockUserSuggestionScreenState: RoomMembersProviderProtocol {
    func fetchMembers(_ members: ([RoomMembersProviderMember]) -> Void) {
        if Self.members == nil {
            Self.members = generateUsersWithCount(10)
        }
        
        members(Self.members)
    }
    
    private func generateUsersWithCount(_ count: UInt) -> [RoomMembersProviderMember] {
        (0..<count).map { _ in
            let identifier = "@" + UUID().uuidString
            return RoomMembersProviderMember(userId: identifier, displayName: identifier, avatarUrl: "mxc://matrix.org/VyNYAgahaiAzUoOeZETtQ")
        }
    }
}
