/*
Copyright 2021-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation
import UIKit

final class TemplateScreenCoordinator: TemplateScreenCoordinatorProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: TemplateScreenCoordinatorParameters
    private var templateScreenViewModel: TemplateScreenViewModelProtocol
    private let templateScreenViewController: TemplateScreenViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: TemplateScreenCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(parameters: TemplateScreenCoordinatorParameters) {
        self.parameters = parameters
        let templateScreenViewModel = TemplateScreenViewModel(session: self.parameters.session)
        let templateScreenViewController = TemplateScreenViewController.instantiate(with: templateScreenViewModel)
        self.templateScreenViewModel = templateScreenViewModel
        self.templateScreenViewController = templateScreenViewController
    }
    
    // MARK: - Public
    
    func start() {            
        self.templateScreenViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.templateScreenViewController
    }
}

// MARK: - TemplateScreenViewModelCoordinatorDelegate
extension TemplateScreenCoordinator: TemplateScreenViewModelCoordinatorDelegate {
    
    func templateScreenViewModel(_ viewModel: TemplateScreenViewModelProtocol, didCompleteWithUserDisplayName userDisplayName: String?) {
        self.delegate?.templateScreenCoordinator(self, didCompleteWithUserDisplayName: userDisplayName)
    }
    
    func templateScreenViewModelDidCancel(_ viewModel: TemplateScreenViewModelProtocol) {
        self.delegate?.templateScreenCoordinatorDidCancel(self)
    }
}
