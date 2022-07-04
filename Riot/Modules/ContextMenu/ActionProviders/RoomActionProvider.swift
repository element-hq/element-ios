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

/// `RoomActionProvider` provides the menu for `MXRoom` instances
@available(iOS 13.0, *)
class RoomActionProvider: RoomActionProviderProtocol {

    // MARK: - Properties
    
    private let service: RoomContextActionService
    
    // MARK: - Setup
    
    init(service: RoomContextActionService) {
        self.service = service
    }
    
    // MARK: - RoomActionProviderProtocol
    
    var menu: UIMenu {
        if service.isRoomJoined {
            var children = service.hasUnread ? [self.markAsReadAction] : []
            children.append(contentsOf: [
                self.directChatAction,
                self.notificationsAction,
                self.favouriteAction,
                self.lowPriorityAction,
                self.leaveAction
            ])
            return UIMenu(children: children)
        } else {
            if service.roomMembership == .invite {
                return UIMenu(children: [
                    self.acceptInviteAction,
                    self.declineInviteAction
                ])
            } else {
                return UIMenu(children: [
                    self.joinAction
                ])
            }
        }
    }
    
    // MARK: - Private
    
    private var directChatAction: UIAction {
        return UIAction(
            title: service.isRoomDirect ? VectorL10n.homeContextMenuMakeRoom : VectorL10n.homeContextMenuMakeDm,
            image: UIImage(systemName: service.isRoomDirect  ? "person.crop.circle.badge.xmark" : "person.circle")) { [weak self] action in
                guard let self = self else { return }
                self.service.isRoomDirect = !self.service.isRoomDirect
        }
    }
    
    private var notificationsAction: UIAction {
        let notificationsImage: UIImage?
        let notificationsTitle: String
        if BuildSettings.showNotificationsV2 {
            notificationsTitle = VectorL10n.homeContextMenuNotifications
            notificationsImage = UIImage(systemName: "bell")
        } else {
            notificationsTitle = service.isRoomMuted ? VectorL10n.homeContextMenuUnmute : VectorL10n.homeContextMenuMute
            notificationsImage = UIImage(systemName: service.isRoomMuted ? "bell.slash": "bell")
        }

        return UIAction(
            title: notificationsTitle,
            image: notificationsImage) { [weak self] action in
                guard let self = self else { return }
                self.service.isRoomMuted = !self.service.isRoomMuted
        }
    }
    
    private var favouriteAction: UIAction {
        return UIAction(
            title: self.service.isRoomFavourite ? VectorL10n.homeContextMenuUnfavourite : VectorL10n.homeContextMenuFavourite,
            image: UIImage(systemName: self.service.isRoomFavourite ? "star.slash" : "star")) { [weak self] action in
                guard let self = self else { return }
                self.service.isRoomFavourite = !self.service.isRoomFavourite
        }
    }

    private var lowPriorityAction: UIAction {
        return UIAction(
            title: self.service.isRoomLowPriority ? VectorL10n.homeContextMenuNormalPriority : VectorL10n.homeContextMenuLowPriority,
            image: UIImage(systemName: self.service.isRoomLowPriority ? "arrow.up" : "arrow.down")) { [weak self] action in
                guard let self = self else { return }
                self.service.isRoomLowPriority = !self.service.isRoomLowPriority
        }
    }
    
    private var markAsReadAction: UIAction {
        return UIAction(
            title: VectorL10n.homeContextMenuMarkAsRead,
            image: UIImage(systemName: "envelope.open")) { [weak self] action in
                guard let self = self else { return }
                self.service.markAsRead()
        }
    }
    
    private var leaveAction: UIAction {
        let image = UIImage(systemName: "rectangle.righthalf.inset.fill.arrow.right")
        let action = UIAction(title: VectorL10n.homeContextMenuLeave, image: image) { [weak self] action in
            guard let self = self else { return }
            self.service.leaveRoom(promptUser: true)
        }
        action.attributes = .destructive
        return action
    }
    
    private var acceptInviteAction: UIAction {
        return UIAction(
            title: VectorL10n.accept) { [weak self] action in
                guard let self = self else { return }
                self.service.joinRoom()
        }
    }
    
    private var declineInviteAction: UIAction {
        let action = UIAction(
            title: VectorL10n.decline) { [weak self] action in
                guard let self = self else { return }
                self.service.leaveRoom(promptUser: false)
        }
        action.attributes = .destructive
        return action
    }
    
    private var joinAction: UIAction {
        return UIAction(
            title: VectorL10n.join) { [weak self] action in
                guard let self = self else { return }
                self.service.joinRoom()
        }
    }
}
