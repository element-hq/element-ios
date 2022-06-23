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
import UIKit
import SwiftUI

final class RoomNotificationSettingsCoordinator: RoomNotificationSettingsCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    private var roomNotificationSettingsViewModel: RoomNotificationSettingsViewModelType
    private let roomNotificationSettingsViewController: UIViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: RoomNotificationSettingsCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(room: MXRoom, presentedModally: Bool = true) {
        let roomNotificationService = MXRoomNotificationSettingsService(room: room)
        let showAvatar = presentedModally
        let avatarData = showAvatar ? AvatarInput(
            mxContentUri: room.summary.avatar,
            matrixItemId: room.roomId,
            displayName: room.summary.displayname
        ) : nil
        let viewModel = RoomNotificationSettingsSwiftUIViewModel(
            roomNotificationService: roomNotificationService,
            avatarData: avatarData,
            displayName: room.summary.displayname,
            roomEncrypted: room.summary.isEncrypted)
        let avatarService: AvatarServiceProtocol = AvatarService(mediaManager: room.mxSession.mediaManager)
        let view = RoomNotificationSettings(viewModel: viewModel, presentedModally: presentedModally)
            .addDependency(avatarService)
        let viewController = VectorHostingController(rootView: view)
        self.roomNotificationSettingsViewModel = viewModel
        self.roomNotificationSettingsViewController = viewController
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
