// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceRoomList/SpaceChildRoomDetail ShowSpaceChildRoomDetail
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

final class SpaceChildRoomDetailCoordinator: SpaceChildRoomDetailCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private var spaceChildRoomDetailViewModel: SpaceChildRoomDetailViewModelType
    private let spaceChildRoomDetailViewController: SpaceChildRoomDetailViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: SpaceChildRoomDetailCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(parameters: SpaceChildRoomDetailCoordinatorParameters) {
        let spaceChildRoomDetailViewModel = SpaceChildRoomDetailViewModel(parameters: parameters)
        let spaceChildRoomDetailViewController = SpaceChildRoomDetailViewController.instantiate(with: spaceChildRoomDetailViewModel)
        self.spaceChildRoomDetailViewModel = spaceChildRoomDetailViewModel
        self.spaceChildRoomDetailViewController = spaceChildRoomDetailViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.spaceChildRoomDetailViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.spaceChildRoomDetailViewController
    }
    
    func toSlidingPresentable() -> UIViewController & SlidingModalPresentable {
        return self.spaceChildRoomDetailViewController
    }
}

// MARK: - SpaceChildRoomDetailViewModelCoordinatorDelegate
extension SpaceChildRoomDetailCoordinator: SpaceChildRoomDetailViewModelCoordinatorDelegate {
    func spaceChildRoomDetailViewModel(_ viewModel: SpaceChildRoomDetailViewModelType, didOpenRoomWith roomId: String) {
        self.delegate?.spaceChildRoomDetailCoordinator(self, didOpenRoomWith: roomId)
    }
    
    func spaceChildRoomDetailViewModelDidCancel(_ viewModel: SpaceChildRoomDetailViewModelType) {
        self.delegate?.spaceChildRoomDetailCoordinatorDidCancel(self)
    }
}
