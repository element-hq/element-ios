// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationRooms SpaceCreationRooms
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
            .addDependency(AvatarService.instantiate(mediaManager: parameters.session.mediaManager))
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
        return self.spaceCreationRoomsHostingController
    }
}
