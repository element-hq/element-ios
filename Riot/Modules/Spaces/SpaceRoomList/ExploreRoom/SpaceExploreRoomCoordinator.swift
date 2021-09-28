// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceRoomList/ExploreRoom ShowSpaceExploreRoom
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

final class SpaceExploreRoomCoordinator: SpaceExploreRoomCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private var spaceExploreRoomViewModel: SpaceExploreRoomViewModelType
    private let spaceExploreRoomViewController: SpaceExploreRoomViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: SpaceExploreRoomCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(parameters: SpaceExploreRoomCoordinatorParameters) {
        let spaceExploreRoomViewModel = SpaceExploreRoomViewModel(parameters: parameters)
        let spaceExploreRoomViewController = SpaceExploreRoomViewController.instantiate(with: spaceExploreRoomViewModel)
        self.spaceExploreRoomViewModel = spaceExploreRoomViewModel
        self.spaceExploreRoomViewController = spaceExploreRoomViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.spaceExploreRoomViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.spaceExploreRoomViewController
    }
}

// MARK: - SpaceExploreRoomViewModelCoordinatorDelegate
extension SpaceExploreRoomCoordinator: SpaceExploreRoomViewModelCoordinatorDelegate {
    func spaceExploreRoomViewModel(_ viewModel: SpaceExploreRoomViewModelType, didSelect item: SpaceExploreRoomListItemViewData, from sourceView: UIView?) {
        self.delegate?.spaceExploreRoomCoordinator(self, didSelect: item, from: sourceView)
    }
    
    func spaceExploreRoomViewModelDidCancel(_ viewModel: SpaceExploreRoomViewModelType) {
        self.delegate?.spaceExploreRoomCoordinatorDidCancel(self)
    }
}
