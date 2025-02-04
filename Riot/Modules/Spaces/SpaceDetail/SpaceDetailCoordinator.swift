// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit

struct SpaceDetailCoordinatorParameters {
    let spaceId: String
    let session: MXSession
    let showCancel: Bool
}

enum SpaceDetailCoordinatorResult {
    case cancel
    case dismiss
    case open
    case join
}

/// Space detail screen
final class SpaceDetailCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: SpaceDetailCoordinatorParameters
    private var viewModel: SpaceDetailViewModel!
    private let viewController: SpaceDetailViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((SpaceDetailCoordinatorResult) -> Void)?

    // MARK: - Setup
    
    init(parameters: SpaceDetailCoordinatorParameters) {
        self.parameters = parameters
        
        let viewModel = SpaceDetailViewModel(session: parameters.session, spaceId: parameters.spaceId)
        let viewController = SpaceDetailViewController.instantiate(mediaManager: parameters.session.mediaManager, viewModel: viewModel, showCancel: parameters.showCancel)
        self.viewModel = viewModel
        self.viewController = viewController
    }
    
    // MARK: - Public methods
    
    func start() {
        self.viewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.viewController
    }
}

// MARK: - SpaceDetailModelViewModelCoordinatorDelegate

extension SpaceDetailCoordinator: SpaceDetailModelViewModelCoordinatorDelegate {
    func spaceDetailViewModelDidJoin(_ viewModel: SpaceDetailViewModelType) {
        completion?(.join)
    }
    
    func spaceDetailViewModelDidOpen(_ viewModel: SpaceDetailViewModelType) {
        completion?(.open)
    }
    
    func spaceDetailViewModelDidCancel(_ viewModel: SpaceDetailViewModelType) {
        completion?(.cancel)
    }
    
    func spaceDetailViewModelDidDismiss(_ viewModel: SpaceDetailViewModelType) {
        completion?(.dismiss)
    }
}
