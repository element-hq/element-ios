// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationPostProcess SpaceCreationPostProcess
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
            .addDependency(AvatarService.instantiate(mediaManager: parameters.session.mediaManager))
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
