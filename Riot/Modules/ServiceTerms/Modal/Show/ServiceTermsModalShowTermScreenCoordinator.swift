// File created from ScreenTemplate
// $ createScreen.sh Modal/Show ServiceTermsModalShowTermScreen
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

final class ServiceTermsModalShowTermScreenCoordinator: ServiceTermsModalShowTermScreenCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private

    private var serviceTermsModalShowTermScreenViewModel: ServiceTermsModalShowTermScreenViewModelType
    private let serviceTermsModalShowTermScreenViewController: ServiceTermsModalShowTermScreenViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: ServiceTermsModalShowTermScreenCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(policy: MXLoginPolicyData, progress: Progress) {
        let serviceTermsModalShowTermScreenViewModel = ServiceTermsModalShowTermScreenViewModel(policy: policy, progress: progress)
        let serviceTermsModalShowTermScreenViewController = ServiceTermsModalShowTermScreenViewController.instantiate(with: serviceTermsModalShowTermScreenViewModel)
        self.serviceTermsModalShowTermScreenViewModel = serviceTermsModalShowTermScreenViewModel
        self.serviceTermsModalShowTermScreenViewController = serviceTermsModalShowTermScreenViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.serviceTermsModalShowTermScreenViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.serviceTermsModalShowTermScreenViewController
    }
}

// MARK: - ServiceTermsModalShowTermScreenViewModelCoordinatorDelegate
extension ServiceTermsModalShowTermScreenCoordinator: ServiceTermsModalShowTermScreenViewModelCoordinatorDelegate {
    func serviceTermsModalShowTermScreenViewModel(_ viewModel: ServiceTermsModalShowTermScreenViewModelType, didAcceptPolicy policy: MXLoginPolicyData) {
        self.delegate?.serviceTermsModalShowTermScreenCoordinator(self, didAcceptPolicy: policy)
    }
 
    func serviceTermsModalShowTermScreenViewModelDidDecline(_ viewModel: ServiceTermsModalShowTermScreenViewModelType) {
        self.delegate?.serviceTermsModalShowTermScreenCoordinatorDidDecline(self)
    }
}
