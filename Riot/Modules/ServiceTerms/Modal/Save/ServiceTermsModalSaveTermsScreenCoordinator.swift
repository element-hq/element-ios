// File created from ScreenTemplate
// $ createScreen.sh Modal/Save ServiceTermsModalSaveTermsScreen
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

final class ServiceTermsModalSaveTermsScreenCoordinator: ServiceTermsModalSaveTermsScreenCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private

    private var serviceTermsModalSaveTermsScreenViewModel: ServiceTermsModalSaveTermsScreenViewModelType
    private let serviceTermsModalSaveTermsScreenViewController: ServiceTermsModalSaveTermsScreenViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: ServiceTermsModalSaveTermsScreenCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(serviceTerms: MXServiceTerms, termsUrls: [String]) {
        let serviceTermsModalSaveTermsScreenViewModel = ServiceTermsModalSaveTermsScreenViewModel(serviceTerms: serviceTerms, termsUrls: termsUrls)
        let serviceTermsModalSaveTermsScreenViewController = ServiceTermsModalSaveTermsScreenViewController.instantiate(with: serviceTermsModalSaveTermsScreenViewModel)
        self.serviceTermsModalSaveTermsScreenViewModel = serviceTermsModalSaveTermsScreenViewModel
        self.serviceTermsModalSaveTermsScreenViewController = serviceTermsModalSaveTermsScreenViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.serviceTermsModalSaveTermsScreenViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.serviceTermsModalSaveTermsScreenViewController
    }
}

// MARK: - ServiceTermsModalSaveTermsScreenViewModelCoordinatorDelegate
extension ServiceTermsModalSaveTermsScreenCoordinator: ServiceTermsModalSaveTermsScreenViewModelCoordinatorDelegate {
    func serviceTermsModalSaveTermsScreenViewModelDidComplete(_ viewModel: ServiceTermsModalSaveTermsScreenViewModelType) {
        self.delegate?.serviceTermsModalSaveTermsScreenCoordinatorDidComplete(self)
    }
    
    func serviceTermsModalSaveTermsScreenViewModelDidCancel(_ viewModel: ServiceTermsModalSaveTermsScreenViewModelType) {
        self.delegate?.serviceTermsModalSaveTermsScreenCoordinatorDidCancel(self)
    }
}
