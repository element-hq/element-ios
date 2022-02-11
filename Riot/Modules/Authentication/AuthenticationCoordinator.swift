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

/// A coordinator that handles authentication, verification and setting a PIN.
final class AuthenticationCoordinator: NSObject, AuthenticationCoordinatorProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let authenticationViewController: AuthenticationViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((MXKAuthenticationType) -> Void)?
    
    // MARK: - Setup
    
    override init() {
        let authenticationViewController = AuthenticationViewController()
        self.authenticationViewController = authenticationViewController
        
        // Preload the view as this can a second and lock up the UI at presentation.
        // The coordinator is initialised early in the onboarding flow to take advantage of this.
        authenticationViewController.loadViewIfNeeded()
        
        super.init()
    }
    
    // MARK: - Public
    
    func start() {
        // Listen to the end of the authentication flow
        authenticationViewController.authVCDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.authenticationViewController
    }
    
    func update(authenticationType: MXKAuthenticationType) {
        authenticationViewController.authType = authenticationType
    }
    
    func showCustomServer() {
        authenticationViewController.setCustomServerFieldsVisible(true)
    }
    
    func update(externalRegistrationParameters: [AnyHashable: Any]) {
        authenticationViewController.externalRegistrationParameters = externalRegistrationParameters
    }
    
    func update(softLogoutCredentials: MXCredentials) {
        authenticationViewController.softLogoutCredentials = softLogoutCredentials
    }
    
    func updateHomeserver(_ homeserver: String?, andIdentityServer identityServer: String?) {
        authenticationViewController.showCustomHomeserver(homeserver, andIdentityServer: identityServer)
    }
    
    func continueSSOLogin(withToken loginToken: String, transactionID: String) -> Bool {
        authenticationViewController.continueSSOLogin(withToken: loginToken, txnId: transactionID)
    }
}

// MARK: - AuthenticationViewControllerDelegate
extension AuthenticationCoordinator: AuthenticationViewControllerDelegate {
    func authenticationViewControllerDidDismiss(_ authenticationViewController: AuthenticationViewController!) {
        completion?(authenticationViewController.authType)
    }
}
