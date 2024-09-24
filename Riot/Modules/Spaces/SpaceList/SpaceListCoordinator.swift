// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceList SpaceList
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation
import UIKit

/// Side menu space list
final class SpaceListCoordinator: SpaceListCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: SpaceListCoordinatorParameters
    private var spaceListViewModel: SpaceListViewModelType
    private let spaceListViewController: SpaceListViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: SpaceListCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(parameters: SpaceListCoordinatorParameters) {
        self.parameters = parameters
        
        let spaceListViewModel = SpaceListViewModel(userSessionsService: self.parameters.userSessionsService)
        let spaceListViewController = SpaceListViewController.instantiate(with: spaceListViewModel)
        self.spaceListViewModel = spaceListViewModel
        self.spaceListViewController = spaceListViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.spaceListViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.spaceListViewController
    }
    
    func revertItemSelection() {
        self.spaceListViewModel.revertItemSelection()
    }
    
    func select(spaceWithId spaceId: String) {
        self.spaceListViewModel.select(spaceWithId: spaceId)
    }
}

// MARK: - SpaceListViewModelCoordinatorDelegate
extension SpaceListCoordinator: SpaceListViewModelCoordinatorDelegate {
    
    func spaceListViewModelDidSelectHomeSpace(_ viewModel: SpaceListViewModelType) {
        self.delegate?.spaceListCoordinatorDidSelectHomeSpace(self)
    }
    
    func spaceListViewModel(_ viewModel: SpaceListViewModelType, didSelectSpaceWithId spaceId: String) {
        self.delegate?.spaceListCoordinator(self, didSelectSpaceWithId: spaceId)
    }
    
    func spaceListViewModel(_ viewModel: SpaceListViewModelType, didSelectInviteWithId spaceId: String, from sourceView: UIView?) {
        self.delegate?.spaceListCoordinator(self, didSelectInviteWithId: spaceId, from: sourceView)
    }
    
    func spaceListViewModel(_ viewModel: SpaceListViewModelType, didPressMoreForSpaceWithId spaceId: String, from sourceView: UIView) {
        self.delegate?.spaceListCoordinator(self, didPressMoreForSpaceWithId: spaceId, from: sourceView)
    }
    
    func spaceListViewModelDidSelectCreateSpace(_ viewModel: SpaceListViewModelType) {
        self.delegate?.spaceListCoordinatorDidSelectCreateSpace(self)
    }
    
}
