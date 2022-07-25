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

import UIKit

struct LegacyAuthenticationCoordinatorParameters {
    let navigationRouter: NavigationRouterType
    /// Whether or not the coordinator should show the loading spinner, key verification etc.
    let canPresentAdditionalScreens: Bool
}

/// A coordinator that handles authentication, verification and setting a PIN using the old UIViewController flow for iOS 12 & 13.
final class LegacyAuthenticationCoordinator: NSObject, AuthenticationCoordinatorProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let navigationRouter: NavigationRouterType
    
    private let authenticationViewController: AuthenticationViewController
    private var canPresentAdditionalScreens: Bool
    private var isWaitingToPresentCompleteSecurity = false
    private var verificationListener: SessionVerificationListener?
    private let authenticationService: AuthenticationService = .shared
    
    /// The session created when successfully authenticated.
    private var session: MXSession?
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: ((AuthenticationCoordinatorResult) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: LegacyAuthenticationCoordinatorParameters) {
        self.navigationRouter = parameters.navigationRouter
        self.canPresentAdditionalScreens = parameters.canPresentAdditionalScreens
        
        let authenticationViewController = AuthenticationViewController()
        self.authenticationViewController = authenticationViewController
        
        // Preload the view as this can a second and lock up the UI at presentation.
        // The coordinator is initialised early in the onboarding flow to take advantage of this.
        authenticationViewController.loadViewIfNeeded()
        
        super.init()
    }
    
    // MARK: - Public
    
    func start() {
        // Listen to the end of the authentication flow.
        authenticationViewController.authVCDelegate = self
        // Set (or clear) any soft-logout credentials.
        authenticationViewController.softLogoutCredentials = authenticationService.softLogoutCredentials
        
        // Configure custom servers if already customised by a deep link.
        let homeserver = authenticationService.state.homeserver.address
        let identityServer = authenticationService.state.identityServer
        if homeserver != BuildSettings.serverConfigDefaultHomeserverUrlString
            || (identityServer != nil && identityServer != BuildSettings.serverConfigDefaultIdentityServerUrlString) {
            authenticationViewController.showCustomHomeserver(homeserver, andIdentityServer: identityServer)
        }
        
        // Listen for further changes from deep links.
        AuthenticationService.shared.delegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.authenticationViewController
    }
    
    func update(authenticationFlow: AuthenticationFlow) {
        authenticationViewController.authType = authenticationFlow.mxkType
    }
    
    func presentPendingScreensIfNecessary() {
        canPresentAdditionalScreens = true
        
        showLoadingAnimation()
        
        if isWaitingToPresentCompleteSecurity {
            isWaitingToPresentCompleteSecurity = false
            presentCompleteSecurity()
        }
    }
    
    // MARK: - Private
    
    private func showLoadingAnimation() {
        let loadingViewController = LaunchLoadingViewController()
        loadingViewController.modalPresentationStyle = .fullScreen
        
        // Replace the navigation stack with the loading animation
        // as there is nothing to navigate back to.
        navigationRouter.setRootModule(loadingViewController)
    }
    
    private func presentCompleteSecurity() {
        guard let session = session else {
            MXLog.error("[LegacyAuthenticationCoordinator] presentCompleteSecurity: Unable to present security due to missing session.")
            authenticationDidComplete()
            return
        }
        
        let isNewSignIn = true
        let cancellable = !session.vc_homeserverConfiguration().encryption.isSecureBackupRequired
        let keyVerificationCoordinator = KeyVerificationCoordinator(session: session, flow: .completeSecurity(isNewSignIn), cancellable: cancellable)
        
        keyVerificationCoordinator.delegate = self
        let presentable = keyVerificationCoordinator.toPresentable()
        presentable.presentationController?.delegate = self
        navigationRouter.present(presentable, animated: true)
        keyVerificationCoordinator.start()
        add(childCoordinator: keyVerificationCoordinator)
    }
    
    private func authenticationDidComplete() {
        callback?(.didComplete)
    }
}

// MARK: - AuthenticationServiceDelegate
extension LegacyAuthenticationCoordinator: AuthenticationServiceDelegate {
    func authenticationService(_ service: AuthenticationService, didReceive ssoLoginToken: String, with transactionID: String) -> Bool {
        authenticationViewController.continueSSOLogin(withToken: ssoLoginToken, txnId: transactionID)
    }

    func authenticationService(_ service: AuthenticationService, didUpdateStateWithLink link: UniversalLink) {
        if link.pathParams.first == "register" && !link.queryParams.isEmpty {
            authenticationViewController.externalRegistrationParameters = link.queryParams
        } else if let homeserver = link.homeserverUrl {
            let identityServer = link.identityServerUrl
            authenticationViewController.showCustomHomeserver(homeserver, andIdentityServer: identityServer)
        }
    }
    
    func authenticationService(_ service: AuthenticationService, needsPromptFor unrecognizedCertificate: Data?, completion: @escaping (Bool) -> Void) {
        // Handled internally in AuthenticationViewController
    }
}

// MARK: - AuthenticationViewControllerDelegate
extension LegacyAuthenticationCoordinator: AuthenticationViewControllerDelegate {
    func authenticationViewController(_ authenticationViewController: AuthenticationViewController,
                                      didLoginWith session: MXSession!,
                                      andPassword password: String?,
                                      orSSOIdentityProvider identityProvider: SSOIdentityProvider?) {
        // Sanity check
        guard let session = session else {
            MXLog.failure("[LegacyAuthenticationCoordinator] authenticationViewController(_:didLoginWith:) The MXSession should not be nil.")
            return
        }
        
        self.session = session
        
        if canPresentAdditionalScreens {
            showLoadingAnimation()
        }
        
        let verificationListener = SessionVerificationListener(session: session, password: password)
        verificationListener.completion = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .needsVerification:
                guard self.canPresentAdditionalScreens else {
                    MXLog.debug("[LegacyAuthenticationCoordinator] Delaying presentCompleteSecurity during onboarding.")
                    self.isWaitingToPresentCompleteSecurity = true
                    return
                }
                
                MXLog.debug("[LegacyAuthenticationCoordinator] Complete security")
                self.presentCompleteSecurity()
            case .authenticationIsComplete:
                self.authenticationDidComplete()
            }
        }
        
        verificationListener.start()
        self.verificationListener = verificationListener
        
        let authenticationType: AuthenticationType
        if let identityProvider = identityProvider {
            authenticationType = .sso(identityProvider)
        } else if !password.isEmptyOrNil {
            authenticationType = .password
        } else {
            authenticationType = .other
        }
        
        callback?(.didLogin(session: session,
                            authenticationFlow: authenticationViewController.authType.flow,
                            authenticationType: authenticationType))
    }
    
    func authenticationViewControllerDidRequestClearAllData(_ authenticationViewController: AuthenticationViewController) {
        callback?(.clearAllData)
    }
}

// MARK: - KeyVerificationCoordinatorDelegate
extension LegacyAuthenticationCoordinator: KeyVerificationCoordinatorDelegate {
    func keyVerificationCoordinatorDidComplete(_ coordinator: KeyVerificationCoordinatorType, otherUserId: String, otherDeviceId: String) {
        if let crypto = session?.crypto,
           !crypto.backup.hasPrivateKeyInCryptoStore || !crypto.backup.enabled {
            MXLog.debug("[LegacyAuthenticationCoordinator][MXKeyVerification] requestAllPrivateKeys: Request key backup private keys")
            crypto.setOutgoingKeyRequestsEnabled(true, onComplete: nil)
        }
        
        navigationRouter.dismissModule(animated: true) { [weak self] in
            self?.authenticationDidComplete()
        }
    }
    
    func keyVerificationCoordinatorDidCancel(_ coordinator: KeyVerificationCoordinatorType) {
        navigationRouter.dismissModule(animated: true) { [weak self] in
            self?.authenticationDidComplete()
        }
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension LegacyAuthenticationCoordinator: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        // Prevent Key Verification from using swipe to dismiss
        return false
    }
}


fileprivate extension AuthenticationFlow {
    var mxkType: MXKAuthenticationType {
        switch self {
        case .login:
            return .login
        case .register:
            return .register
        }
    }
}

fileprivate extension MXKAuthenticationType {
    var flow: AuthenticationFlow {
        switch self {
        case .register:
            return .register
        case .login, .forgotPassword:
            return .login
        @unknown default:
            MXLog.failure("[MXKAuthenticationType] Unknown type exposed to Swift.")
            return .login
        }
    }
}
