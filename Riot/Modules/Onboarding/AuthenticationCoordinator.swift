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
import MatrixSDK

@available(iOS 14.0, *)
struct AuthenticationCoordinatorParameters {
    let navigationRouter: NavigationRouterType
    /// The screen that should be shown when starting the flow.
    let initialScreen: AuthenticationCoordinator.EntryPoint
    /// Whether or not the coordinator should show the loading spinner, key verification etc.
    let canPresentAdditionalScreens: Bool
}

/// A coordinator that handles authentication, verification and setting a PIN.
@available(iOS 14.0, *)
final class AuthenticationCoordinator: NSObject, AuthenticationCoordinatorProtocol {
    
    enum EntryPoint {
        case registration
        case selectServerForRegistration
        case login
    }
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let navigationRouter: NavigationRouterType
    private let authenticationService = AuthenticationService.shared
    
    private let initialScreen: EntryPoint
    private var canPresentAdditionalScreens: Bool
    private var isWaitingToPresentCompleteSecurity = false
    
    private let crossSigningService = CrossSigningService()
    
    /// The password entered, for use when setting up cross-signing.
    private var password: String?
    /// The session created when successfully authenticated.
    private var session: MXSession?
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((AuthenticationCoordinatorResult) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: AuthenticationCoordinatorParameters) {
        self.navigationRouter = parameters.navigationRouter
        self.initialScreen = parameters.initialScreen
        self.canPresentAdditionalScreens = parameters.canPresentAdditionalScreens
        
        super.init()
    }
    
    // MARK: - Public
    
    func start() {
        Task {
            #warning("Catch any errors and handle them")
            let (loginFlowResult, registrationResult) = try await authenticationService.refreshServer(homeserverAddress: authenticationService.homeserverAddress)
            
            if case let .success(session) = registrationResult {
                onSessionCreated(session: session, isAccountCreated: true)
                return
            }
            
            await MainActor.run {
                switch initialScreen {
                case .registration:
                    showRegistrationScreen(registrationResult: registrationResult, loginFlowResult: loginFlowResult)
                case .selectServerForRegistration:
                    showServerSelectionScreen()
                case .login:
                    showLoginScreen()
                }
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        navigationRouter.toPresentable()
    }
    
    func presentPendingScreensIfNecessary() {
        canPresentAdditionalScreens = true
        
        showLoadingAnimation()
        
        if isWaitingToPresentCompleteSecurity {
            isWaitingToPresentCompleteSecurity = false
            presentCompleteSecurity()
        }
    }
    
    // MARK: - Registration
    
    /// Pushes the server selection screen into the flow (other screens may also present it modally later).
    @MainActor private func showServerSelectionScreen() {
        MXLog.debug("[AuthenticationCoordinator] showServerSelectionScreen")
        let parameters = AuthenticationServerSelectionCoordinatorParameters(authenticationService: authenticationService,
                                                                            hasModalPresentation: false)
        let coordinator = AuthenticationServerSelectionCoordinator(parameters: parameters)
        coordinator.completion = { [weak self, weak coordinator] result in
            guard let self = self, let coordinator = coordinator else { return }
            self.serverSelectionCoordinator(coordinator, didCompleteWith: result)
        }
        
        coordinator.start()
        add(childCoordinator: coordinator)
        
        if navigationRouter.modules.isEmpty {
            navigationRouter.setRootModule(coordinator, popCompletion: nil)
        } else {
            navigationRouter.push(coordinator, animated: true) { [weak self] in
                self?.remove(childCoordinator: coordinator)
            }
        }
    }
    
    @available(iOS 14.0, *)
    /// Shows the next screen in the flow after the server selection screen.
    @MainActor private func serverSelectionCoordinator(_ coordinator: AuthenticationServerSelectionCoordinator,
                                                       didCompleteWith result: AuthenticationServerSelectionCoordinatorResult) {
        switch result {
        case .updated(let loginFlow, let registrationResult):
            showRegistrationScreen(registrationResult: registrationResult, loginFlowResult: loginFlow)
        case .dismiss:
            MXLog.failure("[AuthenticationCoordinator] AuthenticationServerSelectionScreen is requesting dismiss when part of a stack.")
        }
    }
    
    /// Shows the registration screen.
    @MainActor private func showRegistrationScreen(registrationResult: RegistrationResult, loginFlowResult: LoginFlowResult) {
        MXLog.debug("[AuthenticationCoordinator] showRegistrationScreen")
        let parameters = AuthenticationRegistrationCoordinatorParameters(navigationRouter: navigationRouter,
                                                                         authenticationService: authenticationService,
                                                                         registrationResult: registrationResult,
                                                                         loginFlowResult: loginFlowResult)
        let coordinator = AuthenticationRegistrationCoordinator(parameters: parameters)
        coordinator.completion = { [weak self, weak coordinator] result in
            guard let self = self, let coordinator = coordinator else { return }
            self.registrationCoordinator(coordinator, didCompleteWith: result)
        }
        
        coordinator.start()
        add(childCoordinator: coordinator)
        
        if navigationRouter.modules.isEmpty {
            navigationRouter.setRootModule(coordinator, popCompletion: nil)
        } else {
            navigationRouter.push(coordinator, animated: true) { [weak self] in
                self?.remove(childCoordinator: coordinator)
            }
        }
    }
    
    /// Displays the next view in the flow after the registration screen.
    @available(iOS 14.0, *)
    @MainActor private func registrationCoordinator(_ coordinator: AuthenticationRegistrationCoordinator, didCompleteWith result: AuthenticationRegistrationCoordinatorResult) {
        switch result {
        case .selectServer:
            showServerSelectionScreen()
        case .flowResponse(let flowResult):
            showNextScreen(for: flowResult)
        case .sessionCreated(let session, let isAccountCreated):
            onSessionCreated(session: session, isAccountCreated: isAccountCreated)
        }
    }
    
    /// Shows the login screen.
    @MainActor private func showLoginScreen() {
        MXLog.debug("[AuthenticationCoordinator] showLoginScreen")
        
    }
    
    // MARK: - Registration Handlers
    /// Determines the next screen to show from the flow result and pushes it.
    func showNextScreen(for flowResult: FlowResult) {
        // TODO
    }
    
    /// Handles the creation of a new session following on from a successful authentication.
    func onSessionCreated(session: MXSession, isAccountCreated: Bool) {
        registerSessionStateChangeNotification(for: session)
        
        self.session = session
        // self.password = password
        
        if canPresentAdditionalScreens {
            showLoadingAnimation()
        }
        
        completion?(.didLogin(session: session, authenticationType: isAccountCreated ? .register : .login))
    }
    
    // MARK: - Additional Screens
    
    /// Replace the contents of the navigation router with a loading animation.
    private func showLoadingAnimation() {
        let loadingViewController = LaunchLoadingViewController()
        loadingViewController.modalPresentationStyle = .fullScreen
        
        // Replace the navigation stack with the loading animation
        // as there is nothing to navigate back to.
        navigationRouter.setRootModule(loadingViewController)
    }
    
    /// Present the key verification screen modally.
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
    
    /// Complete the authentication flow.
    private func authenticationDidComplete() {
        completion?(.didComplete)
    }
    
    private func registerSessionStateChangeNotification(for session: MXSession) {
        NotificationCenter.default.addObserver(self, selector: #selector(sessionStateDidChange), name: .mxSessionStateDidChange, object: session)
    }

    private func unregisterSessionStateChangeNotification() {
        NotificationCenter.default.removeObserver(self, name: .mxSessionStateDidChange, object: nil)
    }
                                      
    @objc private func sessionStateDidChange(_ notification: Notification) {
        guard let session = notification.object as? MXSession else {
            MXLog.error("[LegacyAuthenticationCoordinator] sessionStateDidChange: Missing session in the notification")
            return
        }

        if session.state == .storeDataReady {
            if let crypto = session.crypto, crypto.crossSigning != nil {
                // Do not make key share requests while the "Complete security" is not complete.
                // If the device is self-verified, the SDK will restore the existing key backup.
                // Then, it  will re-enable outgoing key share requests
                crypto.setOutgoingKeyRequestsEnabled(false, onComplete: nil)
            }
        } else if session.state == .running {
            unregisterSessionStateChangeNotification()
            
            if let crypto = session.crypto, let crossSigning = crypto.crossSigning {
                crossSigning.refreshState { [weak self] stateUpdated in
                    guard let self = self else { return }
                    
                    MXLog.debug("[LegacyAuthenticationCoordinator] sessionStateDidChange: crossSigning.state: \(crossSigning.state)")
                    
                    switch crossSigning.state {
                    case .notBootstrapped:
                        // TODO: This is still not sure we want to disable the automatic cross-signing bootstrap
                        // if the admin disabled e2e by default.
                        // Do like riot-web for the moment
                        if session.vc_homeserverConfiguration().encryption.isE2EEByDefaultEnabled {
                            // Bootstrap cross-signing on user's account
                            // We do it for both registration and new login as long as cross-signing does not exist yet
                            if let password = self.password, !password.isEmpty {
                                MXLog.debug("[LegacyAuthenticationCoordinator] sessionStateDidChange: Bootstrap with password")
                                
                                crossSigning.setup(withPassword: password) {
                                    MXLog.debug("[LegacyAuthenticationCoordinator] sessionStateDidChange: Bootstrap succeeded")
                                    self.authenticationDidComplete()
                                } failure: { error in
                                    MXLog.error("[LegacyAuthenticationCoordinator] sessionStateDidChange: Bootstrap failed. Error: \(error)")
                                    crypto.setOutgoingKeyRequestsEnabled(true, onComplete: nil)
                                    self.authenticationDidComplete()
                                }
                            } else {
                                // Try to setup cross-signing without authentication parameters in case if a grace period is enabled
                                self.crossSigningService.setupCrossSigningWithoutAuthentication(for: session) {
                                    MXLog.debug("[LegacyAuthenticationCoordinator] sessionStateDidChange: Bootstrap succeeded without credentials")
                                    self.authenticationDidComplete()
                                } failure: { error in
                                    MXLog.error("[LegacyAuthenticationCoordinator] sessionStateDidChange: Do not know how to bootstrap cross-signing. Skip it.")
                                    crypto.setOutgoingKeyRequestsEnabled(true, onComplete: nil)
                                    self.authenticationDidComplete()
                                }
                            }
                        } else {
                            crypto.setOutgoingKeyRequestsEnabled(true, onComplete: nil)
                            self.authenticationDidComplete()
                        }
                    case .crossSigningExists:
                        guard self.canPresentAdditionalScreens else {
                            MXLog.debug("[LegacyAuthenticationCoordinator] sessionStateDidChange: Delaying presentCompleteSecurity during onboarding.")
                            self.isWaitingToPresentCompleteSecurity = true
                            return
                        }
                        
                        MXLog.debug("[LegacyAuthenticationCoordinator] sessionStateDidChange: Complete security")
                        self.presentCompleteSecurity()
                    default:
                        MXLog.debug("[LegacyAuthenticationCoordinator] sessionStateDidChange: Nothing to do")
                        
                        crypto.setOutgoingKeyRequestsEnabled(true, onComplete: nil)
                        self.authenticationDidComplete()
                    }
                } failure: { [weak self] error in
                    MXLog.error("[LegacyAuthenticationCoordinator] sessionStateDidChange: Fail to refresh crypto state with error: \(error)")
                    crypto.setOutgoingKeyRequestsEnabled(true, onComplete: nil)
                    self?.authenticationDidComplete()
                }
            } else {
                authenticationDidComplete()
            }
        }
    }
}

// MARK: - KeyVerificationCoordinatorDelegate
@available(iOS 14.0, *)
extension AuthenticationCoordinator: KeyVerificationCoordinatorDelegate {
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
@available(iOS 14.0, *)
extension AuthenticationCoordinator: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        // Prevent Key Verification from using swipe to dismiss
        return false
    }
}



// MARK: - Unused conformances
@available(iOS 14.0, *)
extension AuthenticationCoordinator {
    var customServerFieldsVisible: Bool {
        get { false }
        set { /* no-op */ }
    }
    
    func update(authenticationType: MXKAuthenticationType) {
        // unused
    }
    
    func update(externalRegistrationParameters: [AnyHashable: Any]) {
        // unused
    }
    
    func update(softLogoutCredentials: MXCredentials) {
        // unused
    }
    
    func updateHomeserver(_ homeserver: String?, andIdentityServer identityServer: String?) {
        // unused
    }
    
    func continueSSOLogin(withToken loginToken: String, transactionID: String) -> Bool {
        #warning("To be implemented elsewhere")
        return false
    }
}
