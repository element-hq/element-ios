// File created from ScreenTemplate
// $ createScreen.sh Modal/Load ServiceTermsModalLoadTermsScreen
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

final class ServiceTermsModalLoadTermsScreenCoordinator: ServiceTermsModalLoadTermsScreenCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let serviceTerms: MXServiceTerms
    private var serviceTermsModalLoadTermsScreenViewModel: ServiceTermsModalLoadTermsScreenViewModelType
    private let serviceTermsModalLoadTermsScreenViewController: ServiceTermsModalLoadTermsScreenViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: ServiceTermsModalLoadTermsScreenCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(serviceTerms: MXServiceTerms) {
        self.serviceTerms = serviceTerms
        
        let serviceTermsModalLoadTermsScreenViewModel = ServiceTermsModalLoadTermsScreenViewModel(serviceTerms: self.serviceTerms)
        let serviceTermsModalLoadTermsScreenViewController = ServiceTermsModalLoadTermsScreenViewController.instantiate(with: serviceTermsModalLoadTermsScreenViewModel)
        self.serviceTermsModalLoadTermsScreenViewModel = serviceTermsModalLoadTermsScreenViewModel
        self.serviceTermsModalLoadTermsScreenViewController = serviceTermsModalLoadTermsScreenViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.serviceTermsModalLoadTermsScreenViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.serviceTermsModalLoadTermsScreenViewController
    }
}

// MARK: - ServiceTermsModalLoadTermsScreenViewModelCoordinatorDelegate
extension ServiceTermsModalLoadTermsScreenCoordinator: ServiceTermsModalLoadTermsScreenViewModelCoordinatorDelegate {
    func serviceTermsModalLoadTermsScreenViewModel(_ viewModel: ServiceTermsModalLoadTermsScreenViewModelType, didCompleteWithTerms terms: MXLoginTerms?) {
        self.delegate?.serviceTermsModalLoadTermsScreenCoordinator(self, didCompleteWithTerms: terms)
    }

    func serviceTermsModalLoadTermsScreenViewModelDidCancel(_ viewModel: ServiceTermsModalLoadTermsScreenViewModelType) {
        self.delegate?.serviceTermsModalLoadTermsScreenCoordinatorDidCancel(self)
    }
}
