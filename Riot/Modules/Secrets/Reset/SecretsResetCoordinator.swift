// File created from ScreenTemplate
// $ createScreen.sh Secrets/Reset SecretsReset
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
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
    
    // MARK: - Private
    
    private func showAuthentication(with request: AuthenticatedEndpointRequest) {
        
        let reauthenticationCoordinatorParameters =  ReauthenticationCoordinatorParameters(session: self.session,
                                                                                           presenter: self.toPresentable(),
                                                                                           title: nil,
                                                                                           message: VectorL10n.secretsResetAuthenticationMessage,
                                                                                           authenticatedEndpointRequest: request)
        
        let coordinator = ReauthenticationCoordinator(parameters: reauthenticationCoordinatorParameters)
        coordinator.delegate = self
        coordinator.start()
        self.add(childCoordinator: coordinator)
    }
}

// MARK: - SecretsResetViewModelCoordinatorDelegate
extension SecretsResetCoordinator: SecretsResetViewModelCoordinatorDelegate {
    
    func secretsResetViewModel(_ viewModel: SecretsResetViewModelType, needsToAuthenticateWith request: AuthenticatedEndpointRequest) {
        self.showAuthentication(with: request)
    }
    
    func secretsResetViewModelDidResetSecrets(_ viewModel: SecretsResetViewModelType) {
        self.delegate?.secretsResetCoordinatorDidResetSecrets(self)
    }
    
    func secretsResetViewModelDidCancel(_ viewModel: SecretsResetViewModelType) {
        self.delegate?.secretsResetCoordinatorDidCancel(self)
    }
}

// MARK: - ReauthenticationCoordinatorDelegate
extension SecretsResetCoordinator: ReauthenticationCoordinatorDelegate {
    
    func reauthenticationCoordinatorDidComplete(_ coordinator: ReauthenticationCoordinatorType, withAuthenticationParameters authenticationParameters: [String: Any]?) {
        self.secretsResetViewModel.process(viewAction: .authenticationInfoEntered(authenticationParameters ?? [:]))
    }
    
    func reauthenticationCoordinatorDidCancel(_ coordinator: ReauthenticationCoordinatorType) {
        self.secretsResetViewModel.process(viewAction: .authenticationCancelled)
        self.remove(childCoordinator: coordinator)
    }
    
    func reauthenticationCoordinator(_ coordinator: ReauthenticationCoordinatorType, didFailWithError error: Error) {
        self.secretsResetViewModel.update(viewState: .error(error))
        self.remove(childCoordinator: coordinator)
    }
}
