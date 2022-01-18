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
}


/// A coordinator that handles authentication, verification and setting a PIN.
final class AuthenticationCoordinator: NSObject, AuthenticationCoordinatorProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: AuthenticationCoordinatorParameters
    private let authenticationViewController: AuthenticationViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: (() -> Void)?
    
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
        
        // Set authType first as registration parameters or soft logout credentials
        // may update this afterwards to handle those use cases.
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
    
    /// Force a registration process based on a predefined set of parameters from a server provisioning link.
    /// For more information see `AuthenticationViewController.externalRegistrationParameters`.
    func update(externalRegistrationParameters: [AnyHashable: Any]) {
        authenticationViewController.externalRegistrationParameters = externalRegistrationParameters
    }
    
    /// Set up the authentication screen with the specified homeserver and/or identity server.
    func showCustomHomeserver(_ homeserver: String?, andIdentityServer identityServer: String?) {
        authenticationViewController.showCustomHomeserver(homeserver, andIdentityServer: identityServer)
    }
    
    /// When SSO login succeeded, when SFSafariViewController is used, continue login with success parameters.
    func continueSSOLogin(withToken loginToken: String, transactionID: String) -> Bool {
        authenticationViewController.continueSSOLogin(withToken: loginToken, txnId: transactionID)
    }
    
    /// Preload `AuthenticationViewController` from it's xib file to avoid locking up the UI when before presentation.
    static func preload() {
        let authenticationViewController = AuthenticationViewController()
        authenticationViewController.loadViewIfNeeded()
    }
}

// MARK: - AuthenticationViewControllerDelegate
extension AuthenticationCoordinator: AuthenticationViewControllerDelegate {
    func authenticationViewControllerDidDismiss(_ authenticationViewController: AuthenticationViewController!) {
        completion?()
    }
}
