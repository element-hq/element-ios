// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationPostProcess SpaceCreationPostProcess
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation
import SwiftUI
import UIKit

final class SpaceCreationPostProcessCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: SpaceCreationPostProcessCoordinatorParameters
    private let spaceCreationPostProcessHostingController: UIViewController
    private var spaceCreationPostProcessViewModel: SpaceCreationPostProcessViewModelProtocol
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: ((SpaceCreationPostProcessCoordinatorAction) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: SpaceCreationPostProcessCoordinatorParameters) {
        self.parameters = parameters
        let viewModel = SpaceCreationPostProcessViewModel.makeSpaceCreationPostProcessViewModel(spaceCreationPostProcessService: SpaceCreationPostProcessService(session: parameters.session, parentSpaceId: parameters.parentSpaceId, creationParams: parameters.creationParams))
        let view = SpaceCreationPostProcess(viewModel: viewModel.context)
            .environmentObject(AvatarViewModel(avatarService: AvatarService(mediaManager: parameters.session.mediaManager)))
        spaceCreationPostProcessViewModel = viewModel
        let hostingController = VectorHostingController(rootView: view)
        hostingController.isNavigationBarHidden = true
        spaceCreationPostProcessHostingController = hostingController
    }
    
    // MARK: - Public

    func start() {
        MXLog.debug("[SpaceCreationPostProcessCoordinator] did start.")
        spaceCreationPostProcessViewModel.completion = { [weak self] result in
            MXLog.debug("[SpaceCreationPostProcessCoordinator] SpaceCreationPostProcessViewModel did complete with result: \(result).")
            guard let self = self else { return }
            switch result {
            case .cancel:
                self.callback?(.cancel)
            case .done(let spaceId):
                self.callback?(.done(spaceId))
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        spaceCreationPostProcessHostingController
    }
}
