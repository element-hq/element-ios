// 
// Copyright 2022 New Vector Ltd
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

import UIKit
import MatrixSDK

enum AllChatsEditActionProviderOption {
    case exploreRooms
    case createRoom
    case startChat
    case invitePeople
    case spaceMembers
    case spaceSettings
    case leaveSpace
    case createSpace
}

protocol AllChatsEditActionProviderDelegate: AnyObject {
    func allChatsEditActionProvider(_ ationProvider: AllChatsEditActionProvider, didSelect option: AllChatsEditActionProviderOption)
}

/// `AllChatsEditActionProvider` provides the menu for accessing edit screens according to the current parent space
class AllChatsEditActionProvider {
    
    // MARK: - Properties
    
    weak var delegate: AllChatsEditActionProviderDelegate?
    
    // MARK: - Private
    
    private var parentSpace: MXSpace? {
        didSet {
            parentName = parentSpace?.summary?.displayname ?? VectorL10n.spaceTag
        }
    }
    private var parentName: String = VectorL10n.spaceTag
    private var isInviteAvailable: Bool = false
    private var isAddRoomAvailable: Bool = true

    // MARK: - RoomActionProviderProtocol
    
    var menu: UIMenu {
        guard parentSpace != nil else {
            return UIMenu(title: VectorL10n.allChatsTitle, children: [
                self.exploreRoomsAction,
                UIMenu(title: "", options: .displayInline, children: [
                    self.startChatAction,
                    self.createRoomAction,
                    self.createSpaceAction
                ])
            ])
        }
        
        return UIMenu(title: parentName, children: [
            UIMenu(title: "", options: .displayInline, children: [
                self.spaceMembersAction,
                self.exploreRoomsAction,
                self.spaceSettingsAction
            ]),
            UIMenu(title: "", options: .displayInline, children: [
                self.invitePeopleAction,
                self.createRoomAction,
                self.createSpaceAction
            ]),
            self.leaveSpaceAction
        ])
    }
    
    // MARK: - Public
    
    func updateMenu(with session: MXSession?, parentSpace: MXSpace?, completion: @escaping (UIMenu) -> Void) -> UIMenu {
        self.parentSpace = parentSpace
        isInviteAvailable = false
        isAddRoomAvailable = parentSpace == nil
        
        guard let parentSpace = parentSpace, let spaceRoom = parentSpace.room, let session = session else {
            return self.menu
        }
        
        spaceRoom.state { [weak self] roomState in
            guard let self = self else { return }
            
            guard let powerLevels = roomState?.powerLevels, let userId = session.myUserId else {
                return
            }
            let userPowerLevel = powerLevels.powerLevelOfUser(withUserID: userId)

            self.isInviteAvailable = userPowerLevel >= powerLevels.invite
            self.isAddRoomAvailable = userPowerLevel >= parentSpace.minimumPowerLevelForAddingRoom(with: powerLevels)
            
            completion(self.menu)
        }
        
        return self.menu
    }
    
    // MARK: - Private
    
    private var exploreRoomsAction: UIAction {
        UIAction(title: VectorL10n.spacesExploreRooms,
                 image: parentSpace == nil ? UIImage(systemName: "list.bullet") : UIImage(systemName: "list.star"),
                 discoverabilityTitle: VectorL10n.spacesExploreRooms) { [weak self] action in
            guard let self = self else { return }
            
            self.delegate?.allChatsEditActionProvider(self, didSelect: .exploreRooms)
        }
    }
    
    private var createRoomAction: UIAction {
        UIAction(title: parentSpace == nil ? VectorL10n.roomRecentsCreateEmptyRoom : VectorL10n.spacesAddRoom,
                 image: UIImage(systemName: "number"),
                 discoverabilityTitle: VectorL10n.roomRecentsCreateEmptyRoom,
                 attributes: isAddRoomAvailable ? [] : .disabled) { [weak self] action in
            guard let self = self else { return }
            
            self.delegate?.allChatsEditActionProvider(self, didSelect: .createRoom)
        }
    }
    
    private var startChatAction: UIAction {
        UIAction(title: VectorL10n.roomRecentsStartChatWith,
                 image: UIImage(systemName: "person"),
                 discoverabilityTitle: VectorL10n.roomRecentsStartChatWith) { [weak self] action in
            guard let self = self else { return }
            
            self.delegate?.allChatsEditActionProvider(self, didSelect: .startChat)
        }
    }
    
    private var createSpaceAction: UIAction {
        UIAction(title: parentSpace == nil ? VectorL10n.spacesCreateSpaceTitle : VectorL10n.spacesCreateSubspaceTitle,
                 image: UIImage(systemName: "star.fill"),
                 discoverabilityTitle: VectorL10n.spacesCreateSpaceTitle,
                 attributes: isAddRoomAvailable ? [] : .disabled) { [weak self] action in
            guard let self = self else { return }
            
            self.delegate?.allChatsEditActionProvider(self, didSelect: .createSpace)
        }
    }
    
    private var invitePeopleAction: UIAction {
        UIAction(title: VectorL10n.spacesInvitePeople,
                 image: UIImage(systemName: "person.badge.plus"),
                 discoverabilityTitle: VectorL10n.spacesInvitePeople,
                 attributes: isInviteAvailable ? [] : .disabled) { [weak self] action in
            guard let self = self else { return }
            
            self.delegate?.allChatsEditActionProvider(self, didSelect: .invitePeople)
        }
    }
    
    private var spaceMembersAction: UIAction {
        UIAction(title: VectorL10n.roomDetailsPeople,
                 image: UIImage(systemName: "person.3"),
                 discoverabilityTitle: VectorL10n.roomDetailsPeople) { [weak self] action in
            guard let self = self else { return }
            
            self.delegate?.allChatsEditActionProvider(self, didSelect: .spaceMembers)
        }
    }
    
    private var spaceSettingsAction: UIAction {
        UIAction(title: VectorL10n.allChatsEditMenuSpaceSettings,
                 image: UIImage(systemName: "text.badge.star"),
                 discoverabilityTitle: VectorL10n.sideMenuActionSettings) { [weak self] action in
            guard let self = self else { return }
            
            self.delegate?.allChatsEditActionProvider(self, didSelect: .spaceSettings)
        }
    }
    
    private var leaveSpaceAction: UIAction {
        UIAction(title: VectorL10n.allChatsEditMenuLeaveSpace(parentName),
                 image: UIImage(systemName: "rectangle.portrait.and.arrow.right.fill"),
                 discoverabilityTitle: VectorL10n.leave,
                 attributes: .destructive) { [weak self] action in
            guard let self = self else { return }
            
            self.delegate?.allChatsEditActionProvider(self, didSelect: .leaveSpace)
        }
    }
}
