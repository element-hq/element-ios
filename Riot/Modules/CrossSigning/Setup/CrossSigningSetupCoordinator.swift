// File created from FlowTemplate
// $ createRootCoordinator.sh CrossSigning CrossSigningSetup
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
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
        guard let crossSigning = self.parameters.session.crypto?.crossSigning else {
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
