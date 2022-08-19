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
    case createSpace
}

protocol AllChatsEditActionProviderDelegate: AnyObject {
    func allChatsEditActionProvider(_ actionProvider: AllChatsEditActionProvider, didSelect option: AllChatsEditActionProviderOption)
}

/// `AllChatsEditActionProvider` provides the menu for accessing edit screens according to the current parent space
class AllChatsEditActionProvider {
    
    // MARK: - Properties
    
    weak var delegate: AllChatsEditActionProviderDelegate?
    
    // MARK: - Private
    
    private var rootSpaceCount: Int = 0
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
            var createActions = [
                self.createRoomAction,
                self.startChatAction
            ]
            if rootSpaceCount > 0 {
                createActions.insert(self.createSpaceAction, at: 0)
            }
            return UIMenu(title: "", children: [
                self.exploreRoomsAction,
                UIMenu(title: "", options: .displayInline, children: createActions)
            ])
        }
        
        return UIMenu(title: "", children: [
            UIMenu(title: "", options: .displayInline, children: [
                self.exploreRoomsAction
            ]),
            UIMenu(title: "", options: .displayInline, children: [
                self.createSpaceAction,
                self.createRoomAction
            ])
        ])
    }
    
    // MARK: - Public
    
    /// Indicates if the context menu should be updated accordingly to the given parameters.
    ///
    /// If `shouldUpdate()` reutrns `true`, you should update the context menu by calling `updateMenu()`.
    ///
    /// - Parameters:
    ///     - session: The current `MXSession` instance
    ///     - parentSpace: The current parent space (`nil` for home space)
    /// - Returns: `true` if the context menu should be updated (call `updateMenu()` in this case). `false` otherwise
    func shouldUpdate(with session: MXSession?, parentSpace: MXSpace?) -> Bool {
        let rootSpaceCount = session?.spaceService.rootSpaces.count ?? 0
        return parentSpace != self.parentSpace || (rootSpaceCount == 0 && self.rootSpaceCount > 0 || rootSpaceCount > 0 && self.rootSpaceCount == 0)
    }
    
    /// Returns an instance of the updated menu accordingly to the given parameters.
    ///
    /// Some menu items can be disabled depending on the required power levels of the `parentSpace`. Therefore, `updateMenu()` first returns a temporary context menu
    /// with all sensible items disabled, asynchronously fetches power levels of the `parentSpace`, then gives a new instance of the menu with, potentially, all sensible items
    /// enabled via the `completion` callback.
    ///
    /// - Parameters:
    ///     - session: The current `MXSession` instance
    ///     - parentSpace: The current parent space (`nil` for home space)
    ///     - completion: callback called once the power levels of the `parentSpace` have been fetched and the menu items have been computed accordingly.
    /// - Returns: If the `parentSpace` is `nil`, the context menu, the temporary context menu otherwise.
    func updateMenu(with session: MXSession?, parentSpace: MXSpace?, completion: @escaping (UIMenu) -> Void) -> UIMenu {
        self.parentSpace = parentSpace
        self.rootSpaceCount = session?.spaceService.rootSpaces.count ?? 0
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
        UIAction(title: parentSpace == nil ? VectorL10n.spacesExploreRooms : VectorL10n.spacesExploreRoomsFormat(parentName),
                 image: UIImage(systemName: "list.bullet")) { [weak self] action in
            guard let self = self else { return }
            
            self.delegate?.allChatsEditActionProvider(self, didSelect: .exploreRooms)
        }
    }
    
    private var createRoomAction: UIAction {
        UIAction(title: parentSpace == nil ? VectorL10n.roomRecentsCreateEmptyRoom : VectorL10n.spacesAddRoom,
                 image: UIImage(systemName: "number"),
                 attributes: isAddRoomAvailable ? [] : .disabled) { [weak self] action in
            guard let self = self else { return }
            
            self.delegate?.allChatsEditActionProvider(self, didSelect: .createRoom)
        }
    }
    
    private var startChatAction: UIAction {
        UIAction(title: VectorL10n.roomRecentsStartChatWith,
                 image: UIImage(systemName: "person")) { [weak self] action in
            guard let self = self else { return }
            
            self.delegate?.allChatsEditActionProvider(self, didSelect: .startChat)
        }
    }
    
    private var createSpaceAction: UIAction {
        UIAction(title: parentSpace == nil ? VectorL10n.spacesCreateSpaceTitle : VectorL10n.spacesCreateSubspaceTitle,
                 image: UIImage(systemName: "plus"),
                 attributes: isAddRoomAvailable ? [] : .disabled) { [weak self] action in
            guard let self = self else { return }
            
            self.delegate?.allChatsEditActionProvider(self, didSelect: .createSpace)
        }
    }
}
