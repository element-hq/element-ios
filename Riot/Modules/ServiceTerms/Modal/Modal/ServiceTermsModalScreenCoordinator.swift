// File created from ScreenTemplate
// $ createScreen.sh Modal/Show ServiceTermsModalScreen
/*
 Copyright 2019 New Vector Ltd
 
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
