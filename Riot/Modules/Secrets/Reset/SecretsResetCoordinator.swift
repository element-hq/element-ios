// File created from ScreenTemplate
// $ createScreen.sh Secrets/Reset SecretsReset
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

final class SecretsResetCoordinator: SecretsResetCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private var secretsResetViewModel: SecretsResetViewModelType
    private let secretsResetViewController: SecretsResetViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: SecretsResetCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
        
        let secretsResetViewModel = SecretsResetViewModel(session: self.session)
        let secretsResetViewController = SecretsResetViewController.instantiate(with: secretsResetViewModel)
        self.secretsResetViewModel = secretsResetViewModel
        self.secretsResetViewController = secretsResetViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.secretsResetViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.secretsResetViewController
    }
}

// MARK: - SecretsResetViewModelCoordinatorDelegate
extension SecretsResetCoordinator: SecretsResetViewModelCoordinatorDelegate {
    
    func secretsResetViewModelDidResetSecrets(_ viewModel: SecretsResetViewModelType) {
        self.delegate?.secretsResetCoordinatorDidResetSecrets(self)
    }
    
    func secretsResetViewModelDidCancel(_ viewModel: SecretsResetViewModelType) {
        self.delegate?.secretsResetCoordinatorDidCancel(self)
    }
}
