//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
