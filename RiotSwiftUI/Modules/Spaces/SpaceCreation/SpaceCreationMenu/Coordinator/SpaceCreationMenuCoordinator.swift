// File created from TemplateAdvancedRoomsExample
// $ createSwiftUITwoScreen.sh Spaces/SpaceCreation SpaceCreation SpaceCreationMenu SpaceCreationSettings
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation
import SwiftUI
import UIKit

final class SpaceCreationMenuCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: SpaceCreationMenuCoordinatorParameters
    private let spaceCreationMenuHostingController: UIViewController
    private var spaceCreationMenuViewModel: SpaceCreationMenuViewModelProtocol
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: ((SpaceCreationMenuCoordinatorAction) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: SpaceCreationMenuCoordinatorParameters) {
        self.parameters = parameters
        let viewModel = SpaceCreationMenuViewModel(navTitle: parameters.navTitle, creationParams: parameters.creationParams, title: parameters.title, detail: parameters.detail, options: parameters.options)
        let view = SpaceCreationMenu(viewModel: viewModel.context, showBackButton: parameters.showBackButton)
            .environmentObject(AvatarViewModel(avatarService: AvatarService(mediaManager: parameters.session.mediaManager)))
        spaceCreationMenuViewModel = viewModel
        let hostingController = VectorHostingController(rootView: view)
        hostingController.isNavigationBarHidden = true
        spaceCreationMenuHostingController = hostingController
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[SpaceCreationMenuCoordinator] did start.")
        spaceCreationMenuViewModel.callback = { [weak self] result in
            MXLog.debug("[SpaceCreationMenuCoordinator] SpaceCreationMenuViewModel did complete with result \(result).")
            guard let self = self else { return }
            switch result {
            case .didSelectOption(let optionId):
                self.callback?(.didSelectOption(optionId))
            case .cancel:
                self.callback?(.cancel)
            case .back:
                self.callback?(.back)
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        spaceCreationMenuHostingController
    }
}
