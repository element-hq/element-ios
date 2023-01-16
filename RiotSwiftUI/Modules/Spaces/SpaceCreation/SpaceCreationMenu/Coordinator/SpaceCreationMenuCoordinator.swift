// File created from TemplateAdvancedRoomsExample
// $ createSwiftUITwoScreen.sh Spaces/SpaceCreation SpaceCreation SpaceCreationMenu SpaceCreationSettings
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
