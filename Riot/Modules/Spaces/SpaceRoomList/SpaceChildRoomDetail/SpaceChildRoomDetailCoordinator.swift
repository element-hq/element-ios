// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceRoomList/SpaceChildRoomDetail ShowSpaceChildRoomDetail
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
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
