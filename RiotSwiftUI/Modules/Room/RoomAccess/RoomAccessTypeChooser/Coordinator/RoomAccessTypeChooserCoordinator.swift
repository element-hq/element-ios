//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct RoomAccessTypeChooserCoordinatorParameters {
    let roomId: String
    let allowsRoomUpgrade: Bool
    let session: MXSession
}

final class RoomAccessTypeChooserCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: RoomAccessTypeChooserCoordinatorParameters
    private let roomAccessTypeChooserHostingController: UIViewController
    private var roomAccessTypeChooserViewModel: RoomAccessTypeChooserViewModelProtocol
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: ((RoomAccessTypeChooserCoordinatorAction) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: RoomAccessTypeChooserCoordinatorParameters) {
        self.parameters = parameters
        let viewModel = RoomAccessTypeChooserViewModel(roomAccessTypeChooserService: RoomAccessTypeChooserService(roomId: parameters.roomId, allowsRoomUpgrade: parameters.allowsRoomUpgrade, session: parameters.session))
        let room = parameters.session.room(withRoomId: parameters.roomId)
        let view = RoomAccessTypeChooser(viewModel: viewModel.context, roomName: room?.displayName ?? "")
        roomAccessTypeChooserViewModel = viewModel
        roomAccessTypeChooserHostingController = VectorHostingController(rootView: view)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[RoomAccessTypeChooserCoordinator] did start.")
        roomAccessTypeChooserViewModel.callback = { [weak self] result in
            MXLog.debug("[RoomAccessTypeChooserCoordinator] RoomAccessTypeChooserViewModel did complete with result \(result).")
            guard let self = self else { return }
            switch result {
            case .spaceSelection(let roomId, let accessType):
                self.callback?(.spaceSelection(roomId, accessType))
            case .done(let roomId):
                self.callback?(.done(roomId))
            case .cancel(let roomId):
                self.callback?(.cancel(roomId))
            case .roomUpgradeNeeded(let roomId, let versionOverride):
                self.callback?(.roomUpgradeNeeded(roomId, versionOverride))
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        roomAccessTypeChooserHostingController
    }
    
    func handleRoomUpgradeResult(_ result: RoomUpgradeCoordinatorResult) {
        roomAccessTypeChooserViewModel.handleRoomUpgradeResult(result)
    }
}
