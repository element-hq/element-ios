/*
 Copyright 2020 New Vector Ltd
 
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

final class TemplateScreenCoordinator: TemplateScreenCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private var templateScreenViewModel: TemplateScreenViewModelType
    private let templateScreenViewController: TemplateScreenViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: TemplateScreenCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
        
        let templateScreenViewModel = TemplateScreenViewModel(session: self.session)
        let templateScreenViewController = TemplateScreenViewController.instantiate(with: templateScreenViewModel)
        self.templateScreenViewModel = templateScreenViewModel
        self.templateScreenViewController = templateScreenViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.templateScreenViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.templateScreenViewController
    }
}

// MARK: - TemplateScreenViewModelCoordinatorDelegate
extension TemplateScreenCoordinator: TemplateScreenViewModelCoordinatorDelegate {
    
    func templateScreenViewModel(_ viewModel: TemplateScreenViewModelType, didCompleteWithUserDisplayName userDisplayName: String?) {
        self.delegate?.templateScreenCoordinator(self, didCompleteWithUserDisplayName: userDisplayName)
    }
    
    func templateScreenViewModelDidCancel(_ viewModel: TemplateScreenViewModelType) {
        self.delegate?.templateScreenCoordinatorDidCancel(self)
    }
}
