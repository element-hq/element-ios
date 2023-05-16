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

enum MockCompletionSuggestionScreenState: MockScreenState, CaseIterable {
    case multipleResults
    
    private static var members: [RoomMembersProviderMember]!
    
    var screenType: Any.Type {
        CompletionSuggestionList.self
    }
    
    var screenView: ([Any], AnyView) {
        let service = CompletionSuggestionService(roomMemberProvider: self, commandProvider: self)
        let listViewModel = CompletionSuggestionViewModel(completionSuggestionService: service)
        
        let viewModel = CompletionSuggestionListWithInputViewModel(listViewModel: listViewModel) { textMessage in
            service.processTextMessage(textMessage)
        }
        
        return (
            [service, listViewModel],
            AnyView(CompletionSuggestionListWithInput(viewModel: viewModel)
                .environmentObject(AvatarViewModel.withMockedServices()))
        )
    }
}

extension MockCompletionSuggestionScreenState: RoomMembersProviderProtocol {
    var canMentionRoom: Bool { false }
    
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

extension MockCompletionSuggestionScreenState: CommandsProviderProtocol {
    var isRoomAdmin: Bool { false }

    func fetchCommands(_ commands: @escaping ([CommandsProviderCommand]) -> Void) {
        commands([
            CommandsProviderCommand(name: "/ban",
                                    parametersFormat: "<user-id> [<reason>]",
                                    description: "Bans user with given id",
                                    requiresAdminPowerLevel: false),
            CommandsProviderCommand(name: "/invite",
                                    parametersFormat: "<user-id>",
                                    description: "Invites user with given id to current room",
                                    requiresAdminPowerLevel: false),
            CommandsProviderCommand(name: "/join",
                                    parametersFormat: "<room-address>",
                                    description: "Joins room with given address",
                                    requiresAdminPowerLevel: false),
            CommandsProviderCommand(name: "/op",
                                    parametersFormat: "<user-id> <power-level>",
                                    description: "Define the power level of a user",
                                    requiresAdminPowerLevel: true),
            CommandsProviderCommand(name: "/deop",
                                    parametersFormat: "<user-id>",
                                    description: "Deops user with given id",
                                    requiresAdminPowerLevel: true),
            CommandsProviderCommand(name: "/me",
                                    parametersFormat: "<message>",
                                    description: "Displays action",
                                    requiresAdminPowerLevel: false)
        ])
    }
}
