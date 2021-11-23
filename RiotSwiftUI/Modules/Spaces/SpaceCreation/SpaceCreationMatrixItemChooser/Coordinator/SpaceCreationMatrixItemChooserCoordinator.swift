// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationMatrixItemChooser SpaceCreationMatrixItemChooser
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
import SwiftUI

final class SpaceCreationMatrixItemChooserCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: SpaceCreationMatrixItemChooserCoordinatorParameters
    private let spaceCreationMatrixItemChooserHostingController: UIViewController
    private var spaceCreationMatrixItemChooserViewModel: SpaceCreationMatrixItemChooserViewModelProtocol
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: ((SpaceCreationMatrixItemChooserCoordinatorAction) -> Void)?
    
    // MARK: - Setup
    
    @available(iOS 14.0, *)
    init(parameters: SpaceCreationMatrixItemChooserCoordinatorParameters) {
        self.parameters = parameters
        let service = SpaceCreationMatrixItemChooserService(session: parameters.session, type: parameters.type, selectedItemIds: [])
        let viewModel = SpaceCreationMatrixItemChooserViewModel.makeSpaceCreationMatrixItemChooserViewModel(spaceCreationMatrixItemChooserService: service, creationParams: parameters.creationParams)
        let view = SpaceCreationMatrixItemChooser(viewModel: viewModel.context)
            .addDependency(AvatarService.instantiate(mediaManager: parameters.session.mediaManager))
        spaceCreationMatrixItemChooserViewModel = viewModel
        let hostingController = VectorHostingController(rootView: view)
        hostingController.hidesBackTitleWhenPushed = true
        spaceCreationMatrixItemChooserHostingController = hostingController
    }
    
    // MARK: - Public
    func start() {
        MXLog.debug("[SpaceCreationMatrixItemChooserCoordinator] did start.")
        spaceCreationMatrixItemChooserViewModel.callback = { [weak self] result in
            MXLog.debug("[SpaceCreationMatrixItemChooserCoordinator] SpaceCreationMatrixItemChooserViewModel did complete with result: \(result).")
            guard let self = self else { return }
            switch result {
            case .cancel:
                self.callback?(.cancel)
            case .done:
                self.callback?(.done)
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.spaceCreationMatrixItemChooserHostingController
    }
}
