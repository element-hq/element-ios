// File created from ScreenTemplate
// $ createScreen.sh Onboarding Authentication
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

import Foundation
import UIKit

/// AuthenticationCoordinator input parameters
struct AuthenticationCoordinatorParameters {
    /// The initial type of authentication to be shown
    let authenticationType: MXKAuthenticationType
    /// The registration parameters.
    let externalRegistrationParameters: [AnyHashable: Any]?
    /// The credentials to use after a soft logout has taken place.
    let softLogoutCredentials: MXCredentials?
    /// Controls whether a back button item will be shown to navigate back in the flow
    let isPartOfFlow: Bool
}


final class AuthenticationCoordinator: NSObject, AuthenticationCoordinatorProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: AuthenticationCoordinatorParameters
    private let authenticationViewController: AuthenticationViewController
    
    // MARK: Public
    
    enum CompletionResult {
        case success
        case navigateBack
    }

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((CompletionResult) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: AuthenticationCoordinatorParameters) {
        self.parameters = parameters
        
        let authenticationViewController = AuthenticationViewController()
        self.authenticationViewController = authenticationViewController
        
        super.init()
    }
    
    // MARK: - Public
    
    func start() {
        // Listen to the end of the authentication flow
        authenticationViewController.authVCDelegate = self
        
        // Must be set first as the bar buttons are refreshed when authType changes.
        authenticationViewController.isPartOfFlow = parameters.isPartOfFlow
        authenticationViewController.authType = parameters.authenticationType
        
        if let externalRegistrationParameters = parameters.externalRegistrationParameters {
            authenticationViewController.externalRegistrationParameters = externalRegistrationParameters
        }
        if let softLogoutCredentials = parameters.softLogoutCredentials {
            authenticationViewController.softLogoutCredentials = softLogoutCredentials
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.authenticationViewController
    }
    
    func update(externalRegistrationParameters: [AnyHashable: Any]) {
        authenticationViewController.externalRegistrationParameters = externalRegistrationParameters
    }
    
    func showCustomHomeserver(_ homeserver: String?, andIdentityServer identityServer: String?) {
        authenticationViewController.showCustomHomeserver(homeserver, andIdentityServer: identityServer)
    }
    
    func continueSSOLogin(withToken loginToken: String, transactionID: String) -> Bool {
        authenticationViewController.continueSSOLogin(withToken: loginToken, txnId: transactionID)
    }
    
    static func preload() {
        let authenticationViewController = AuthenticationViewController()
        authenticationViewController.loadViewIfNeeded()
    }
}

// MARK: - AuthenticationViewModelCoordinatorDelegate
extension AuthenticationCoordinator: AuthenticationViewControllerDelegate {
    func authenticationViewControllerDidTapBackButton(_ authenticationViewController: AuthenticationViewController!) {
        completion?(.navigateBack)
    }
    
    func authenticationViewControllerDidDismiss(_ authenticationViewController: AuthenticationViewController!) {
        completion?(.success)
    }
}
