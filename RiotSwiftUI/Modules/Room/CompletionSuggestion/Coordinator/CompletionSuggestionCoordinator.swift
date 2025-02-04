//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import SwiftUI
import UIKit
import WysiwygComposer

protocol CompletionSuggestionCoordinatorDelegate: AnyObject {
    func completionSuggestionCoordinator(_ coordinator: CompletionSuggestionCoordinator, didRequestMentionForMember member: MXRoomMember, textTrigger: String?)
    func completionSuggestionCoordinatorDidRequestMentionForRoom(_ coordinator: CompletionSuggestionCoordinator, textTrigger: String?)
    func completionSuggestionCoordinator(_ coordinator: CompletionSuggestionCoordinator, didRequestCommand command: String, textTrigger: String?)
    func completionSuggestionCoordinator(_ coordinator: CompletionSuggestionCoordinator, didUpdateViewHeight height: CGFloat)
}

struct CompletionSuggestionCoordinatorParameters {
    let mediaManager: MXMediaManager
    let room: MXRoom
    let userID: String
}

/// Wrapper around `CompletionSuggestionViewModelType.Context` to pass it through obj-c.
final class CompletionSuggestionViewModelContextWrapper: NSObject {
    let context: CompletionSuggestionViewModelType.Context

    init(context: CompletionSuggestionViewModelType.Context) {
        self.context = context
    }
}

final class CompletionSuggestionCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: CompletionSuggestionCoordinatorParameters
    
    private var completionSuggestionHostingController: UIHostingController<AnyView>
    private var completionSuggestionService: CompletionSuggestionServiceProtocol
    private var completionSuggestionViewModel: CompletionSuggestionViewModelProtocol
    private var roomMemberProvider: CompletionSuggestionCoordinatorRoomMemberProvider
    private var commandProvider: CompletionSuggestionCoordinatorCommandProvider

    private var cancellables = Set<AnyCancellable>()
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: (() -> Void)?
    
    weak var delegate: CompletionSuggestionCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(parameters: CompletionSuggestionCoordinatorParameters) {
        self.parameters = parameters
        
        roomMemberProvider = CompletionSuggestionCoordinatorRoomMemberProvider(room: parameters.room, userID: parameters.userID)
        commandProvider = CompletionSuggestionCoordinatorCommandProvider(room: parameters.room, userID: parameters.userID)
        completionSuggestionService = CompletionSuggestionService(roomMemberProvider: roomMemberProvider, commandProvider: commandProvider)
        
        let viewModel = CompletionSuggestionViewModel(completionSuggestionService: completionSuggestionService)
        let view = CompletionSuggestionList(viewModel: viewModel.context)
            .environmentObject(AvatarViewModel(avatarService: AvatarService(mediaManager: parameters.mediaManager)))
        
        completionSuggestionViewModel = viewModel
        completionSuggestionHostingController = VectorHostingController(rootView: view)
        
        completionSuggestionViewModel.completion = { [weak self] result in
            guard let self = self else {
                return
            }
            
            switch result {
            case .selectedItemWithIdentifier(let identifier):
                if identifier == CompletionSuggestionUserID.room {
                    self.delegate?.completionSuggestionCoordinatorDidRequestMentionForRoom(self, textTrigger: self.completionSuggestionService.currentTextTrigger)
                    return
                }
                
                if let member = self.roomMemberProvider.roomMembers.filter({ $0.userId == identifier }).first {
                    self.delegate?.completionSuggestionCoordinator(self, didRequestMentionForMember: member, textTrigger: self.completionSuggestionService.currentTextTrigger)
                } else if let command = self.commandProvider.commands.filter({ $0.cmd == identifier }).first {
                    self.delegate?.completionSuggestionCoordinator(self, didRequestCommand: command.cmd, textTrigger: self.completionSuggestionService.currentTextTrigger)
                }
            }
        }

        completionSuggestionService.items.sink { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.completionSuggestionCoordinator(self, didUpdateViewHeight: self.calculateViewHeight())
        }.store(in: &cancellables)
    }
    
    func processTextMessage(_ textMessage: String) {
        completionSuggestionService.processTextMessage(textMessage)
    }

    func processSuggestionPattern(_ suggestionPattern: SuggestionPattern?) {
        completionSuggestionService.processSuggestionPattern(suggestionPattern)
    }

    // MARK: - Public

    func start() { }
    
    func toPresentable() -> UIViewController {
        completionSuggestionHostingController
    }

    func sharedContext() -> CompletionSuggestionViewModelContextWrapper {
        CompletionSuggestionViewModelContextWrapper(context: completionSuggestionViewModel.sharedContext)
    }

    // MARK: - Private

    private func calculateViewHeight() -> CGFloat {
        let viewModel = CompletionSuggestionViewModel(completionSuggestionService: completionSuggestionService)
        let view = CompletionSuggestionList(viewModel: viewModel.context)
            .environmentObject(AvatarViewModel(avatarService: AvatarService(mediaManager: parameters.mediaManager)))

        let controller = VectorHostingController(rootView: view)
        guard let view = controller.view else {
            return 0
        }
        view.isHidden = true

        toPresentable().view.addSubview(view)
        controller.didMove(toParent: toPresentable())

        view.setNeedsLayout()
        view.layoutIfNeeded()

        let result = view.intrinsicContentSize.height

        controller.didMove(toParent: nil)
        view.removeFromSuperview()

        return result
    }
}

private class CompletionSuggestionCoordinatorRoomMemberProvider: RoomMembersProviderProtocol {
    private let room: MXRoom
    private let userID: String
    
    var roomMembers: [MXRoomMember] = []
    var canMentionRoom = false
    
    init(room: MXRoom, userID: String) {
        self.room = room
        self.userID = userID
        updateWithPowerLevels()
    }
    
    /// Gets the power levels for the room to update suggestions accordingly.
    func updateWithPowerLevels() {
        room.state { [weak self] state in
            guard let self, let powerLevels = state?.powerLevels else { return }
            let userPowerLevel = powerLevels.powerLevelOfUser(withUserID: self.userID)
            let mentionRoomPowerLevel = powerLevels.minimumPowerLevel(forNotifications: kMXRoomPowerLevelNotificationsRoomKey,
                                                                      defaultPower: kMXRoomPowerLevelNotificationsRoomDefault)
            self.canMentionRoom = userPowerLevel >= mentionRoomPowerLevel
        }
    }
    
    func fetchMembers(_ members: @escaping ([RoomMembersProviderMember]) -> Void) {
        room.members { [weak self] roomMembers in
            guard let self = self, let joinedMembers = roomMembers?.joinedMembers else {
                return
            }
            self.roomMembers = joinedMembers
            members(self.roomMembersToProviderMembers(joinedMembers))
        } lazyLoadedMembers: { [weak self] lazyRoomMembers in
            guard let self = self, let joinedMembers = lazyRoomMembers?.joinedMembers else {
                return
            }
            self.roomMembers = joinedMembers
            members(self.roomMembersToProviderMembers(joinedMembers))
        } failure: { error in
            MXLog.error("[CompletionSuggestionCoordinatorRoomMemberProvider] Failed loading room", context: error)
        }
    }
    
    private func roomMembersToProviderMembers(_ roomMembers: [MXRoomMember]) -> [RoomMembersProviderMember] {
        roomMembers.map { RoomMembersProviderMember(userId: $0.userId, displayName: $0.displayname ?? "", avatarUrl: $0.avatarUrl ?? "") }
    }
}

private class CompletionSuggestionCoordinatorCommandProvider: CommandsProviderProtocol {
    private let room: MXRoom
    private let userID: String

    var commands = MXKSlashCommand.allCases
    var isRoomAdmin = false

    init(room: MXRoom, userID: String) {
        self.room = room
        self.userID = userID
        updateWithPowerLevels()
    }

    func updateWithPowerLevels() {
        room.state { [weak self] state in
            guard let self, let powerLevels = state?.powerLevels else { return }

            let userPowerLevel = powerLevels.powerLevelOfUser(withUserID: self.userID)
            self.isRoomAdmin = RoomPowerLevel(rawValue: userPowerLevel) == .admin
        }
    }

    func fetchCommands(_ commands: @escaping ([CommandsProviderCommand]) -> Void) {
        commands(self.commands.map { CommandsProviderCommand(name: $0.cmd, parametersFormat: $0.parametersFormat, description: $0.description, requiresAdminPowerLevel: $0.requiresAdminPowerLevel) })
    }
}

private extension MXKSlashCommand {
    var description: String {
        switch self {
        case .changeDisplayName:
            return VectorL10n.roomCommandChangeDisplayNameDescription
        case .emote:
            return VectorL10n.roomCommandEmoteDescription
        case .joinRoom:
            return VectorL10n.roomCommandJoinRoomDescription
        case .partRoom:
            return VectorL10n.roomCommandPartRoomDescription
        case .inviteUser:
            return VectorL10n.roomCommandInviteUserDescription
        case .kickUser:
            return VectorL10n.roomCommandKickUserDescription
        case .banUser:
            return VectorL10n.roomCommandBanUserDescription
        case .unbanUser:
            return VectorL10n.roomCommandUnbanUserDescription
        case .setUserPowerLevel:
            return VectorL10n.roomCommandSetUserPowerLevelDescription
        case .resetUserPowerLevel:
            return VectorL10n.roomCommandResetUserPowerLevelDescription
        case .changeRoomTopic:
            return VectorL10n.roomCommandChangeRoomTopicDescription
        case .discardSession:
            return VectorL10n.roomCommandDiscardSessionDescription
        }
    }

    // Note: for now only filter out `/op` and `/deop` (same as Element-Web),
    // but we could use power level for ban/invite/etc to filter further.
    var requiresAdminPowerLevel: Bool {
        switch self {
        case .setUserPowerLevel, .resetUserPowerLevel:
            return true
        default:
            return false
        }
    }
}
