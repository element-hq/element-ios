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
    
    private var verificationListener: SessionVerificationListener?
    
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
            do {
                let flow: AuthenticationFlow = initialScreen == .login ? .login : .registration
                try await authenticationService.startFlow(flow, for: authenticationService.state.homeserver.address)
            } catch {
                MXLog.error("[AuthenticationCoordinator] start: Failed to start")
                await MainActor.run { displayError(error) }
                return
            }
            
            await MainActor.run {
                switch initialScreen {
                case .registration:
                    showRegistrationScreen()
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
    
    // MARK: - Private
    
    /// Presents an alert on top of the navigation router, using the supplied error's `localizedDescription`.
    @MainActor func displayError(_ error: Error) {
        let alert = UIAlertController(title: VectorL10n.error,
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: VectorL10n.ok, style: .default))
        
        toPresentable().present(alert, animated: true)
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
        case .updated:
            showRegistrationScreen()
        case .dismiss:
            MXLog.failure("[AuthenticationCoordinator] AuthenticationServerSelectionScreen is requesting dismiss when part of a stack.")
        }
    }
    
    /// Shows the registration screen.
    @MainActor private func showRegistrationScreen() {
        MXLog.debug("[AuthenticationCoordinator] showRegistrationScreen")
        let homeserver = authenticationService.state.homeserver
        let parameters = AuthenticationRegistrationCoordinatorParameters(navigationRouter: navigationRouter,
                                                                         authenticationService: authenticationService,
                                                                         registrationFlow: homeserver.registrationFlow,
                                                                         loginMode: homeserver.preferredLoginMode)
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
    @MainActor private func registrationCoordinator(_ coordinator: AuthenticationRegistrationCoordinator,
                                                    didCompleteWith result: AuthenticationRegistrationCoordinatorResult) {
        switch result {
        case .selectServer:
            showServerSelectionScreen()
        case .completed(let result):
            handleRegistrationResult(result)
        }
    }
    
    /// Shows the login screen.
    @MainActor private func showLoginScreen() {
        MXLog.debug("[AuthenticationCoordinator] showLoginScreen")
        
    }
    
    // MARK: - Registration Handlers
    /// Determines the next screen to show from the flow result and pushes it.
    func handleRegistrationResult(_ result: RegistrationResult) {
        switch result {
        case .success(let mxSession):
            onSessionCreated(session: mxSession, isAccountCreated: true)
        case .flowResponse(let flowResult):
            // TODO
            break
        }
    }
    
    /// Handles the creation of a new session following on from a successful authentication.
    func onSessionCreated(session: MXSession, isAccountCreated: Bool) {
        self.session = session
        // self.password = password
        
        if canPresentAdditionalScreens {
            showLoadingAnimation()
        }
        
        let verificationListener = SessionVerificationListener(session: session, password: password)
        
        verificationListener.completion = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .needsVerification:
                guard self.canPresentAdditionalScreens else {
                    MXLog.debug("[AuthenticationCoordinator] Delaying presentCompleteSecurity during onboarding.")
                    self.isWaitingToPresentCompleteSecurity = true
                    return
                }
                
                MXLog.debug("[AuthenticationCoordinator] Complete security")
                self.presentCompleteSecurity()
            case .authenticationIsComplete:
                self.authenticationDidComplete()
            }
        }
        
        verificationListener.start()
        self.verificationListener = verificationListener
        
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
