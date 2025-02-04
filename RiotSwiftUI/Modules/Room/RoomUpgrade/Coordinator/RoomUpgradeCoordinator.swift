//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import MatrixSDK
import SwiftUI

struct RoomUpgradeCoordinatorParameters {
    let session: MXSession
    let roomId: String
    let parentSpaceId: String?
    let versionOverride: String
}

final class RoomUpgradeCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: RoomUpgradeCoordinatorParameters
    private let roomUpgradeHostingController: UIViewController
    private var roomUpgradeViewModel: RoomUpgradeViewModelProtocol
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((RoomUpgradeCoordinatorResult) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: RoomUpgradeCoordinatorParameters) {
        self.parameters = parameters
        let viewModel = RoomUpgradeViewModel.makeRoomUpgradeViewModel(roomUpgradeService: RoomUpgradeService(session: parameters.session, roomId: parameters.roomId, parentSpaceId: parameters.parentSpaceId, versionOverride: parameters.versionOverride))
        let view = RoomUpgrade(viewModel: viewModel.context)
            .environmentObject(AvatarViewModel(avatarService: AvatarService(mediaManager: parameters.session.mediaManager)))
        roomUpgradeViewModel = viewModel
        roomUpgradeHostingController = VectorHostingController(rootView: view)
        roomUpgradeHostingController.view.backgroundColor = .clear
    }
    
    // MARK: - Public

    func start() {
        MXLog.debug("[RoomUpgradeCoordinator] did start.")
        roomUpgradeViewModel.completion = { [weak self] result in
            MXLog.debug("[RoomUpgradeCoordinator] RoomUpgradeViewModel did complete with result: \(result).")
            guard let self = self else { return }
            switch result {
            case .cancel(let roomId):
                self.completion?(.cancel(roomId))
            case .done(let roomId):
                self.completion?(.done(roomId))
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        roomUpgradeHostingController
    }
}
