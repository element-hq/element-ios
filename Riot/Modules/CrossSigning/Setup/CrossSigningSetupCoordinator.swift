// File created from FlowTemplate
// $ createRootCoordinator.sh CrossSigning CrossSigningSetup
/*
 Copyright 2021 New Vector Ltd
 
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

import UIKit

@objcMembers
final class CrossSigningSetupCoordinator: CrossSigningSetupCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: CrossSigningSetupCoordinatorParameters
    private let crossSigningService: CrossSigningService
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: CrossSigningSetupCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(parameters: CrossSigningSetupCoordinatorParameters) {
        self.parameters = parameters
        self.crossSigningService = CrossSigningService()
    }    
    
    // MARK: - Public methods
    
    func start() {
        self.showReauthentication()
    }
    
    func toPresentable() -> UIViewController {
        return self.parameters.presenter.toPresentable()
    }
    
    // MARK: - Private methods

    private func showReauthentication() {
        
        let setupCrossSigningRequest = self.crossSigningService.setupCrossSigningRequest()
        
        let reauthenticationParameters = ReauthenticationCoordinatorParameters(session: parameters.session,
                                                                               presenter: parameters.presenter,
                                                                               title: parameters.title,
                                                                               message: parameters.message,
                                                                               authenticatedEndpointRequest: setupCrossSigningRequest)
        
        let coordinator = ReauthenticationCoordinator(parameters: reauthenticationParameters)
        coordinator.delegate = self
        self.add(childCoordinator: coordinator)
        
        coordinator.start()
    }
    
    private func setupCrossSigning(with authenticationParameters: [String: Any]) {
        guard let crossSigning = self.parameters.session.crypto.crossSigning else {
            return
        }
        
        crossSigning.setup(withAuthParams: authenticationParameters) { [weak self] in
            guard let self = self else {
                return
            }
            self.delegate?.crossSigningSetupCoordinatorDidComplete(self)
        } failure: { [weak self] error in
            guard let self = self else {
                return
            }
            self.delegate?.crossSigningSetupCoordinator(self, didFailWithError: error)
        }
    }
}

// MARK: - ReauthenticationCoordinatorDelegate
extension CrossSigningSetupCoordinator: ReauthenticationCoordinatorDelegate {
        
    func reauthenticationCoordinatorDidComplete(_ coordinator: ReauthenticationCoordinatorType, withAuthenticationParameters authenticationParameters: [String: Any]?) {
        self.setupCrossSigning(with: authenticationParameters ?? [:])
    }
    
    func reauthenticationCoordinatorDidCancel(_ coordinator: ReauthenticationCoordinatorType) {
        self.delegate?.crossSigningSetupCoordinatorDidCancel(self)
    }
    
    func reauthenticationCoordinator(_ coordinator: ReauthenticationCoordinatorType, didFailWithError error: Error) {
        self.delegate?.crossSigningSetupCoordinator(self, didFailWithError: error)
    }
}
