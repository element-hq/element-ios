// File created from ScreenTemplate
// $ createScreen.sh Room/NotificationSettings RoomNotificationSettings
/*
 Copyright 2021 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation
import UIKit

final class RoomNotificationSettingsCoordinator: RoomNotificationSettingsCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    private var roomNotificationSettingsViewModel: RoomNotificationSettingsViewModelType
    private let roomNotificationSettingsViewController: RoomNotificationSettingsViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: RoomNotificationSettingsCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(room: MXRoom, showAvatar: Bool = true) {
        let repository = RoomNotificationSettingsService(room: room)
        
        let avatarData = showAvatar ? RoomAvatarViewData(
            roomId: room.roomId,
            displayName: room.summary.displayname,
            avatarUrl: room.summary.avatar,
            mediaManager: room.mxSession.mediaManager
        ) : nil
        let roomNotificationSettingsViewModel = RoomNotificationSettingsViewModel(roomNotificationService: repository, roomEncrypted: room.summary.isEncrypted, avatarViewData: avatarData)
        let roomNotificationSettingsViewController = RoomNotificationSettingsViewController.instantiate(with: roomNotificationSettingsViewModel)
        self.roomNotificationSettingsViewModel = roomNotificationSettingsViewModel
        self.roomNotificationSettingsViewController = roomNotificationSettingsViewController
    }

    // MARK: - Public methods
    
    func start() {            
        self.roomNotificationSettingsViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.roomNotificationSettingsViewController
    }
}

// MARK: - RoomNotificationSettingsViewModelCoordinatorDelegate
extension RoomNotificationSettingsCoordinator: RoomNotificationSettingsViewModelCoordinatorDelegate {
    
    func roomNotificationSettingsViewModelDidComplete(_ viewModel: RoomNotificationSettingsViewModelType) {
        self.delegate?.roomNotificationSettingsCoordinatorDidComplete(self)
    }
    
    func roomNotificationSettingsViewModelDidCancel(_ viewModel: RoomNotificationSettingsViewModelType) {
        self.delegate?.roomNotificationSettingsCoordinatorDidCancel(self)
    }
}
