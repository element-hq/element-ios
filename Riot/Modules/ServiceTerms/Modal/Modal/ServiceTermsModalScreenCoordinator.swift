// File created from ScreenTemplate
// $ createScreen.sh Modal/Show ServiceTermsModalScreen
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation
import UIKit

final class ServiceTermsModalScreenCoordinator: ServiceTermsModalScreenCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private

    private var serviceTermsModalScreenViewModel: ServiceTermsModalScreenViewModelType
    private let serviceTermsModalScreenViewController: ServiceTermsModalScreenViewController

    // Must be used only internally
    var childCoordinators: [Coordinator] = []

    // MARK: Public
    
    weak var delegate: ServiceTermsModalScreenCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(serviceTerms: MXServiceTerms) {
        
        let serviceTermsModalScreenViewModel = ServiceTermsModalScreenViewModel(serviceTerms: serviceTerms)
        let serviceTermsModalScreenViewController = ServiceTermsModalScreenViewController.instantiate(with: serviceTermsModalScreenViewModel)
        self.serviceTermsModalScreenViewModel = serviceTermsModalScreenViewModel
        self.serviceTermsModalScreenViewController = serviceTermsModalScreenViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.serviceTermsModalScreenViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.serviceTermsModalScreenViewController
    }
}

// MARK: - ServiceTermsModalScreenViewModelCoordinatorDelegate
extension ServiceTermsModalScreenCoordinator: ServiceTermsModalScreenViewModelCoordinatorDelegate {

    func serviceTermsModalScreenViewModelDidAccept(_ viewModel: ServiceTermsModalScreenViewModelType) {
        self.delegate?.serviceTermsModalScreenCoordinatorDidAccept(self)
    }

    func serviceTermsModalScreenViewModel(_ coordinator: ServiceTermsModalScreenViewModelType, displayPolicy policy: MXLoginPolicyData) {
        self.delegate?.serviceTermsModalScreenCoordinator(self, displayPolicy: policy)
    }

    func serviceTermsModalScreenViewModelDidDecline(_ viewModel: ServiceTermsModalScreenViewModelType) {
        self.delegate?.serviceTermsModalScreenCoordinatorDidDecline(self)
    }
}
