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
    private let parameters: SpaceExploreRoomCoordinatorParameters
    
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
        self.parameters = parameters
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.spaceExploreRoomViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.spaceExploreRoomViewController
    }
    
    func reloadRooms() {
        spaceExploreRoomViewModel.process(viewAction: .reloadData)
    }
}

// MARK: - SpaceExploreRoomViewModelCoordinatorDelegate
extension SpaceExploreRoomCoordinator: SpaceExploreRoomViewModelCoordinatorDelegate {
    func spaceExploreRoomViewModel(_ viewModel: SpaceExploreRoomViewModelType, openSettingsOf item: SpaceExploreRoomListItemViewData) {
        self.delegate?.spaceExploreRoomCoordinator(self, openSettingsOf: item)
    }
    
    func spaceExploreRoomViewModel(_ coordinator: SpaceExploreRoomViewModelType, inviteTo item: SpaceExploreRoomListItemViewData) {
        self.delegate?.spaceExploreRoomCoordinator(self, inviteTo: item)
    }
    
    func spaceExploreRoomViewModel(_ coordinator: SpaceExploreRoomViewModelType, didSelect item: SpaceExploreRoomListItemViewData, from sourceView: UIView?) {
        self.delegate?.spaceExploreRoomCoordinator(self, didSelect: item, from: sourceView)
    }
    
    func spaceExploreRoomViewModelDidCancel(_ viewModel: SpaceExploreRoomViewModelType) {
        self.delegate?.spaceExploreRoomCoordinatorDidCancel(self)
    }
    
    func spaceExploreRoomViewModelDidAddRoom(_ viewModel: SpaceExploreRoomViewModelType) {
        guard let space = parameters.session.spaceService.getSpace(withId: parameters.spaceId) else {
            showAddRoomMissingPermissionAlert()
            return
        }
        
        space.canAddRoom { canAddRoom in
            if canAddRoom {
                self.delegate?.spaceExploreRoomCoordinatorDidAddRoom(self)
            } else {
                self.showAddRoomMissingPermissionAlert()
            }
        }
    }
    
    func spaceExploreRoomViewModel(_ coordinator: SpaceExploreRoomViewModelType, didJoin item: SpaceExploreRoomListItemViewData) {
        self.delegate?.spaceExploreRoomCoordinator(self, didJoin: item)
    }
    
    private func showAddRoomMissingPermissionAlert() {
        let alert = UIAlertController(title: VectorL10n.spacesAddRoom, message: VectorL10n.spacesAddRoomMissingPermissionMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: VectorL10n.ok, style: .default, handler: nil))
        self.toPresentable().present(alert, animated: true, completion: nil)
    }
}
