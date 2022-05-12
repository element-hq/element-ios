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

struct AuthenticationCoordinatorParameters {
    let navigationRouter: NavigationRouterType
    /// The screen that should be shown when starting the flow.
    let initialScreen: AuthenticationCoordinator.EntryPoint
    /// Whether or not the coordinator should show the loading spinner, key verification etc.
    let canPresentAdditionalScreens: Bool
}

/// A coordinator that handles authentication, verification and setting a PIN.
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
    var callback: ((AuthenticationCoordinatorResult) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: AuthenticationCoordinatorParameters) {
        self.navigationRouter = parameters.navigationRouter
        self.initialScreen = parameters.initialScreen
        self.canPresentAdditionalScreens = parameters.canPresentAdditionalScreens
        
        super.init()
    }
    
    // MARK: - Public
    
    func start() {
        Task { await startAsync() }
    }
    
    /// An async version of `start`.
    ///
    /// Allows the caller to show an activity indicator until the authentication service is ready.
    @MainActor func startAsync() async {
        do {
            let flow: AuthenticationFlow = initialScreen == .login ? .login : .register
            let homeserverAddress = authenticationService.state.homeserver.addressFromUser ?? authenticationService.state.homeserver.address
            try await authenticationService.startFlow(flow, for: homeserverAddress)
        } catch {
            MXLog.error("[AuthenticationCoordinator] start: Failed to start")
            displayError(error)
            return
        }
        
        switch initialScreen {
        case .registration:
            showRegistrationScreen()
        case .selectServerForRegistration:
            showServerSelectionScreen()
        case .login:
            showLoginScreen()
        }
    }
    
    func toPresentable() -> UIViewController {
        navigationRouter.toPresentable()
    }
    
    @MainActor func presentPendingScreensIfNecessary() {
        canPresentAdditionalScreens = true
        
        showLoadingAnimation()
        
        if isWaitingToPresentCompleteSecurity {
            isWaitingToPresentCompleteSecurity = false
            presentCompleteSecurity()
        }
    }
    
    // MARK: - Private
    
    /// Presents an alert on top of the navigation router, using the supplied error's `localizedDescription`.
    @MainActor private func displayError(_ error: Error) {
        let alert = UIAlertController(title: VectorL10n.error,
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: VectorL10n.ok, style: .default))
        
        toPresentable().present(alert, animated: true)
    }
    
    /// Prompts the user to confirm that they would like to cancel the registration flow.
    @MainActor private func displayCancelConfirmation() {
        let alert = UIAlertController(title: VectorL10n.warning,
                                      message: VectorL10n.authenticationCancelFlowConfirmationMessage,
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: VectorL10n.no, style: .cancel))
        alert.addAction(UIAlertAction(title: VectorL10n.yes, style: .default) { [weak self] _ in
            self?.cancelRegistration()
        })
        
        toPresentable().present(alert, animated: true)
    }
    
    /// Cancels the registration flow, handing control back to the onboarding coordinator.
    @MainActor private func cancelRegistration() {
        authenticationService.reset()
        callback?(.cancel(.register))
    }
    
    // MARK: - Registration
    
    /// Pushes the server selection screen into the flow (other screens may also present it modally later).
    @MainActor private func showServerSelectionScreen() {
        MXLog.debug("[AuthenticationCoordinator] showServerSelectionScreen")
        let parameters = AuthenticationServerSelectionCoordinatorParameters(authenticationService: authenticationService,
                                                                            hasModalPresentation: false)
        let coordinator = AuthenticationServerSelectionCoordinator(parameters: parameters)
        coordinator.callback = { [weak self, weak coordinator] result in
            guard let self = self, let coordinator = coordinator else { return }
            self.serverSelectionCoordinator(coordinator, didCompleteWith: result)
        }
        
        coordinator.start()
        add(childCoordinator: coordinator)
        
        if navigationRouter.modules.isEmpty {
            navigationRouter.setRootModule(coordinator) { [weak self] in
                self?.remove(childCoordinator: coordinator)
            }
        } else {
            navigationRouter.push(coordinator, animated: true) { [weak self] in
                self?.remove(childCoordinator: coordinator)
            }
        }
    }
    
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
        coordinator.callback = { [weak self, weak coordinator] result in
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
    @MainActor private func registrationCoordinator(_ coordinator: AuthenticationRegistrationCoordinator,
                                                    didCompleteWith result: AuthenticationRegistrationCoordinatorResult) {
        switch result {
        case .completed(let result):
            handleRegistrationResult(result)
        }
    }
    
    /// Shows the verify email screen.
    @MainActor private func showVerifyEmailScreen() {
        MXLog.debug("[AuthenticationCoordinator] showVerifyEmailScreen")
        guard let registrationWizard = authenticationService.registrationWizard else { fatalError("Handle these errors more gracefully.") }
        
        let parameters = AuthenticationVerifyEmailCoordinatorParameters(registrationWizard: registrationWizard)
        let coordinator = AuthenticationVerifyEmailCoordinator(parameters: parameters)
        coordinator.callback = { [weak self] result in
            self?.registrationStageDidComplete(with: result)
        }
        
        coordinator.start()
        add(childCoordinator: coordinator)
        
        navigationRouter.setRootModule(coordinator, hideNavigationBar: false, animated: true) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }
    
    /// Shows the terms screen.
    @MainActor private func showTermsScreen(terms: MXLoginTerms?) {
        MXLog.debug("[AuthenticationCoordinator] showTermsScreen")
        guard let registrationWizard = authenticationService.registrationWizard else { fatalError("Handle these errors more gracefully.") }
        
        let homeserver = authenticationService.state.homeserver
        let localizedPolicies = terms?.policiesData(forLanguage: Bundle.mxk_language(), defaultLanguage: "en")
        let parameters = AuthenticationTermsCoordinatorParameters(registrationWizard: registrationWizard,
                                                                  localizedPolicies: localizedPolicies ?? [],
                                                                  homeserverAddress: homeserver.addressFromUser ?? homeserver.address)
        let coordinator = AuthenticationTermsCoordinator(parameters: parameters)
        coordinator.callback = { [weak self] result in
            self?.registrationStageDidComplete(with: result)
        }
        
        coordinator.start()
        add(childCoordinator: coordinator)
        
        navigationRouter.setRootModule(coordinator, hideNavigationBar: false, animated: true) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }
    
    @MainActor private func showReCaptchaScreen(siteKey: String) {
        MXLog.debug("[AuthenticationCoordinator] showReCaptchaScreen")
        guard
            let registrationWizard = authenticationService.registrationWizard,
            let homeserverURL = URL(string: authenticationService.state.homeserver.address)
        else { fatalError("Handle these errors more gracefully.") }
        
        let parameters = AuthenticationReCaptchaCoordinatorParameters(registrationWizard: registrationWizard,
                                                                      siteKey: siteKey,
                                                                      homeserverURL: homeserverURL)
        let coordinator = AuthenticationReCaptchaCoordinator(parameters: parameters)
        coordinator.callback = { [weak self] result in
            self?.registrationStageDidComplete(with: result)
        }
        
        coordinator.start()
        add(childCoordinator: coordinator)
        
        navigationRouter.setRootModule(coordinator, hideNavigationBar: false, animated: true) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }
    
    /// Shows the verify email screen.
    @MainActor private func showVerifyMSISDNScreen() {
        MXLog.debug("[AuthenticationCoordinator] showVerifyMSISDNScreen")
        fatalError("Phone verification not implemented yet.")
    }
    
    /// Displays the next view in the registration flow.
    @MainActor private func registrationStageDidComplete(with result: AuthenticationRegistrationStageResult) {
        switch result {
        case .completed(let result):
            handleRegistrationResult(result)
        case .cancel:
            displayCancelConfirmation()
        }
    }
    
    /// Shows the login screen.
    @MainActor private func showLoginScreen() {
        MXLog.debug("[AuthenticationCoordinator] showLoginScreen")
        
    }
    
    // MARK: - Registration Handlers
    /// Determines the next screen to show from the flow result and pushes it.
    @MainActor private func handleRegistrationResult(_ result: RegistrationResult) {
        switch result {
        case .success(let mxSession):
            onSessionCreated(session: mxSession, flow: .register)
        case .flowResponse(let flowResult):
            MXLog.debug("[AuthenticationCoordinator] handleRegistrationResult: Missing stages - \(flowResult.missingStages)")
            
            guard let nextStage = flowResult.nextUncompletedStage else {
                MXLog.failure("[AuthenticationCoordinator] There are no remaining stages.")
                return
            }
            
            showStage(nextStage)
        }
    }
    
    @MainActor private func showStage(_ stage: FlowResult.Stage) {
        switch stage {
        case .reCaptcha(_, let siteKey):
            showReCaptchaScreen(siteKey: siteKey)
        case .email:
            showVerifyEmailScreen()
        case .msisdn:
            showVerifyMSISDNScreen()
        case .dummy:
            MXLog.failure("[AuthenticationCoordinator] Attempting to perform the dummy stage.")
        case .terms(_, let terms):
            showTermsScreen(terms: terms)
        case .other:
            #warning("Show fallback")
            MXLog.failure("[AuthenticationCoordinator] Attempting to perform an unsupported stage.")
        }
    }
    
    /// Handles the creation of a new session following on from a successful authentication.
    @MainActor private func onSessionCreated(session: MXSession, flow: AuthenticationFlow) {
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
        
        #warning("Add authentication type to the new flow")
        callback?(.didLogin(session: session, authenticationFlow: flow, authenticationType: .other))
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
        callback?(.didComplete)
    }
}

// MARK: - KeyVerificationCoordinatorDelegate
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
extension AuthenticationCoordinator: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        // Prevent Key Verification from using swipe to dismiss
        return false
    }
}



// MARK: - Unused conformances
extension AuthenticationCoordinator {
    var customServerFieldsVisible: Bool {
        get { false }
        set { /* no-op */ }
    }
    
    func update(authenticationFlow: AuthenticationFlow) {
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
