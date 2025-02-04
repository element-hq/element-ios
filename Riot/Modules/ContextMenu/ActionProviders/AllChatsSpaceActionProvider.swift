// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit
import MatrixSDK

enum AllChatsSpaceActionProviderOption {
    case invitePeople
    case spaceMembers
    case spaceSettings
    case leaveSpace
}

protocol AllChatsSpaceActionProviderDelegate: AnyObject {
    func allChatsSpaceActionProvider(_ actionProvider: AllChatsSpaceActionProvider, didSelect option: AllChatsSpaceActionProviderOption)
}

/// `AllChatsSpaceActionProvider` provides the menu for accessing space options according to the current space
class AllChatsSpaceActionProvider {
    
    // MARK: - Properties
    
    weak var delegate: AllChatsSpaceActionProviderDelegate?
    
    // MARK: - Private

    private var currentSpace: MXSpace? {
        didSet {
            spaceName = currentSpace?.summary?.displayName ?? VectorL10n.spaceTag
        }
    }
    private var spaceName: String = VectorL10n.spaceTag
    private var isInviteAvailable: Bool = false

    // MARK: - RoomActionProviderProtocol
    
    var menu: UIMenu {
        guard currentSpace != nil else {
            return UIMenu(title: "", children: [])
        }
        
        return UIMenu(title: "", children: [
            UIMenu(title: "", options: .displayInline, children: [
                self.spaceSettingsAction,
                self.spaceMembersAction,
                self.invitePeopleAction
            ]),
            self.leaveSpaceAction
        ])
    }
    
    // MARK: - Public
    
    /// Returns an instance of the updated menu accordingly to the given parameters.
    ///
    /// Some menu items can be disabled depending on the required power levels of the `parentSpace`. Therefore, `updateMenu()` first returns a temporary context menu
    /// with all sensible items disabled, asynchronously fetches power levels of the `parentSpace`, then gives a new instance of the menu with, potentially, all sensible items
    /// enabled via the `completion` callback.
    ///
    /// - Parameters:
    ///     - session: The current `MXSession` instance
    ///     - space: The current space (`nil` for home space)
    ///     - completion: callback called once the power levels of the `parentSpace` have been fetched and the menu items have been computed accordingly.
    /// - Returns: If the `parentSpace` is `nil`, the context menu, the temporary context menu otherwise.
    func updateMenu(with session: MXSession?, space: MXSpace?, completion: @escaping (UIMenu) -> Void) -> UIMenu {
        self.currentSpace = space
        isInviteAvailable = false
        
        guard let currentSpace = currentSpace, let spaceRoom = currentSpace.room, let session = session else {
            return self.menu
        }
        
        spaceRoom.state { [weak self] roomState in
            guard let self = self else { return }
            
            guard let powerLevels = roomState?.powerLevels, let userId = session.myUserId else {
                return
            }
            let userPowerLevel = powerLevels.powerLevelOfUser(withUserID: userId)

            self.isInviteAvailable = userPowerLevel >= powerLevels.invite
            
            completion(self.menu)
        }
        
        return self.menu
    }
    
    // MARK: - Private
    
    private var invitePeopleAction: UIAction {
        UIAction(title: VectorL10n.inviteTo(spaceName),
                 image: UIImage(systemName: "square.and.arrow.up"),
                 attributes: isInviteAvailable ? [] : .disabled) { [weak self] action in
            guard let self = self else { return }
            
            self.delegate?.allChatsSpaceActionProvider(self, didSelect: .invitePeople)
        }
    }
    
    private var spaceMembersAction: UIAction {
        UIAction(title: VectorL10n.roomDetailsPeople,
                 image: UIImage(systemName: "person")) { [weak self] action in
            guard let self = self else { return }
            
            self.delegate?.allChatsSpaceActionProvider(self, didSelect: .spaceMembers)
        }
    }
    
    private var spaceSettingsAction: UIAction {
        UIAction(title: VectorL10n.allChatsEditMenuSpaceSettings,
                 image: UIImage(systemName: "gearshape")) { [weak self] action in
            guard let self = self else { return }
            
            self.delegate?.allChatsSpaceActionProvider(self, didSelect: .spaceSettings)
        }
    }
    
    private var leaveSpaceAction: UIAction {
        UIAction(title: VectorL10n.allChatsEditMenuLeaveSpace(spaceName),
                 image: UIImage(systemName: "rectangle.portrait.and.arrow.right.fill"),
                 attributes: .destructive) { [weak self] action in
            guard let self = self else { return }
            
            self.delegate?.allChatsSpaceActionProvider(self, didSelect: .leaveSpace)
        }
    }
}
