//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI
import UIKit

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
            displayName: room.summary.displayName
        ) : nil
        let viewModel = RoomNotificationSettingsSwiftUIViewModel(
            roomNotificationService: roomNotificationService,
            avatarData: avatarData,
            displayName: room.summary.displayName,
            roomEncrypted: room.summary.isEncrypted
        )
        let avatarService: AvatarServiceProtocol = AvatarService(mediaManager: room.mxSession.mediaManager)
        let view = RoomNotificationSettings(viewModel: viewModel, presentedModally: presentedModally)
            .environmentObject(AvatarViewModel(avatarService: avatarService))
        let viewController = VectorHostingController(rootView: view)
        roomNotificationSettingsViewModel = viewModel
        roomNotificationSettingsViewController = viewController
    }

    // MARK: - Public methods
    
    func start() {
        roomNotificationSettingsViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        roomNotificationSettingsViewController
    }
}

// MARK: - RoomNotificationSettingsViewModelCoordinatorDelegate

extension RoomNotificationSettingsCoordinator: RoomNotificationSettingsViewModelCoordinatorDelegate {
    func roomNotificationSettingsViewModelDidComplete(_ viewModel: RoomNotificationSettingsViewModelType) {
        delegate?.roomNotificationSettingsCoordinatorDidComplete(self)
    }
    
    func roomNotificationSettingsViewModelDidCancel(_ viewModel: RoomNotificationSettingsViewModelType) {
        delegate?.roomNotificationSettingsCoordinatorDidCancel(self)
    }
}
