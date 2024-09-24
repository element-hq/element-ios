// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationRooms SpaceCreationRooms
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation
import SwiftUI
import UIKit

final class SpaceCreationRoomsCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: SpaceCreationRoomsCoordinatorParameters
    private let spaceCreationRoomsHostingController: UIViewController
    private var spaceCreationRoomsViewModel: SpaceCreationRoomsViewModelProtocol
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: ((SpaceCreationRoomsCoordinatorAction) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: SpaceCreationRoomsCoordinatorParameters) {
        self.parameters = parameters
        let viewModel = SpaceCreationRoomsViewModel(creationParameters: parameters.creationParams)
        let view = SpaceCreationRooms(viewModel: viewModel.context)
            .environmentObject(AvatarViewModel(avatarService: AvatarService(mediaManager: parameters.session.mediaManager)))
        spaceCreationRoomsViewModel = viewModel
        let hostingController = VectorHostingController(rootView: view)
        hostingController.isNavigationBarHidden = true
        spaceCreationRoomsHostingController = hostingController
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[SpaceCreationRoomsCoordinator] did start.")
        spaceCreationRoomsViewModel.callback = { [weak self] result in
            MXLog.debug("[SpaceCreationRoomsCoordinator] SpaceCreationRoomsViewModel did complete with result: \(result).")
            guard let self = self else { return }
            switch result {
            case .cancel:
                self.callback?(.cancel)
            case .back:
                self.callback?(.back)
            case .done:
                self.callback?(.didSetupRooms)
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        spaceCreationRoomsHostingController
    }
}
