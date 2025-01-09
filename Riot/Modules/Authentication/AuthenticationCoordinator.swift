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
import CommonKit

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
        case login
    }
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let navigationRouter: NavigationRouterType
    private let authenticationService = AuthenticationService.shared
    
    /// The initial screen to be shown when starting the coordinator.
    private let initialScreen: EntryPoint
    /// The type of authentication that was used to complete the flow.
    private var authenticationType: AuthenticationType?
    
    /// The presenter used to handler authentication via SSO.
    private var ssoAuthenticationPresenter: SSOAuthenticationPresenter?
    /// The transaction ID used when presenting the SSO screen. Used when completing via a deep link.
    private var ssoTransactionID: String?
    
    /// Whether the coordinator can present further screens after a successful login has occurred.
    private var canPresentAdditionalScreens: Bool
    /// `true` if presentation of the verification screen is blocked by `canPresentAdditionalScreens`.
    private var isWaitingToPresentCompleteSecurity = false
    
    /// The listener object that informs the coordinator whether verification needs to be presented or not.
    private var verificationListener: SessionVerificationListener?

    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var successIndicator: UserIndicator?
    
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

        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: parameters.navigationRouter.toPresentable())
        
        super.init()
    }
    
    // MARK: - Public
    
    func start() {
        Task { @MainActor in
            await startAuthenticationFlow()
            callback?(.didStart)
            authenticationService.delegate = self
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
    
    /// Starts the authentication flow.
    @MainActor private func startAuthenticationFlow() async {
        if let softLogoutCredentials = authenticationService.softLogoutCredentials,
           let homeserverAddress = softLogoutCredentials.homeServer {
            do {
                try await authenticationService.startFlow(.login, for: homeserverAddress)
            } catch {
                MXLog.error("[AuthenticationCoordinator] start: Failed to start")
                displayError(message: error.localizedDescription)
            }

            await showSoftLogoutScreen(softLogoutCredentials)

            return
        }

        let flow: AuthenticationFlow = initialScreen == .login ? .login : .register

        // Check if the user must select a server
        if BuildSettings.forceHomeserverSelection, authenticationService.provisioningLink?.homeserverUrl == nil {
            showServerSelectionScreen(for: flow)
            return
        }
        
        var showReplacementAppBanner = false
        do {
            // Start the flow (if homeserverAddress is nil, the default server will be used).
            try await authenticationService.startFlow(flow)
        } catch RegistrationError.delegatedOIDCRequiresReplacementApp where BuildSettings.replacementApp != nil {
            // The flow can continue, allowing the Registration Screen to display the banner.
            showReplacementAppBanner = true
        } catch {
            MXLog.error("[AuthenticationCoordinator] start: Failed to start, showing server selection.")
            showServerSelectionScreen(for: flow)
            return
        }

        switch initialScreen {
        case .registration:
            if authenticationService.state.homeserver.needsRegistrationFallback {
                showFallback(for: flow)
            } else {
                showRegistrationScreen(showReplacementAppBanner: showReplacementAppBanner)
            }
        case .login:
            if authenticationService.state.homeserver.needsLoginFallback {
                showFallback(for: flow)
            } else {
                showLoginScreen()
            }
        }
    }
    
    /// Pushes the server selection screen into the flow (other screens may also present it modally later).
    @MainActor private func showServerSelectionScreen(for flow: AuthenticationFlow) {
        MXLog.debug("[AuthenticationCoordinator] showServerSelectionScreen")
        let parameters = AuthenticationServerSelectionCoordinatorParameters(authenticationService: authenticationService,
                                                                            flow: flow,
                                                                            hasModalPresentation: false)
        let coordinator = AuthenticationServerSelectionCoordinator(parameters: parameters)
        coordinator.callback = { [weak self, weak coordinator] result in
            guard let self = self, let coordinator = coordinator else { return }
            self.serverSelectionCoordinator(coordinator, didCompleteWith: result, for: flow)
        }
        
        coordinator.start()
        add(childCoordinator: coordinator)
        
        navigationRouter.push(coordinator, animated: true) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }
    
    /// Shows the next screen in the flow after the server selection screen.
    @MainActor private func serverSelectionCoordinator(_ coordinator: AuthenticationServerSelectionCoordinator,
                                                       didCompleteWith result: AuthenticationServerSelectionCoordinatorResult,
                                                       for flow: AuthenticationFlow) {
        switch result {
        case .updated:
            if flow == .register {
                showRegistrationScreen()
            } else {
                showLoginScreen()
            }
        case .dismiss:
            MXLog.failure("[AuthenticationCoordinator] AuthenticationServerSelectionScreen is requesting dismiss when part of a stack.")
        }
    }
    
    /// Presents an alert on top of the navigation router with the supplied error message.
    @MainActor private func displayError(message: String) {
        let alert = UIAlertController(title: VectorL10n.error, message: message, preferredStyle: .alert)
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
    
    /// Prompts the user to trust a certificate by displaying its fingerprint (SHA256).
    @MainActor private func displayUnrecognizedCertificateAlert(for certificate: Data) async -> Bool {
        await withCheckedContinuation { continuation in
            let title = VectorL10n.sslCouldNotVerify
            let homeserverURLString = VectorL10n.sslHomeserverUrl(authenticationService.state.homeserver.displayableAddress)
            let fingerprint = VectorL10n.sslFingerprintHash("SHA256")
            let certificateFingerprint = (certificate as NSData).mx_SHA256AsHexString() ?? VectorL10n.error
            
            let message = [VectorL10n.sslCertNotTrust,
                           VectorL10n.sslCertNewAccountExpl,
                           homeserverURLString,
                           fingerprint,
                           certificateFingerprint,
                           VectorL10n.sslOnlyAccept]
                .joined(separator: "\n\n")
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: VectorL10n.cancel, style: .cancel) { action in
                continuation.resume(with: .success(false))
            })
            
            alert.addAction(UIAlertAction(title: VectorL10n.sslTrust, style: .default) { action in
                continuation.resume(with: .success(true))
            })
            
            // The alert will be encountered on the current stack or when server selection is being presented.
            let presentingViewController = toPresentable().presentedViewController ?? toPresentable()
            presentingViewController.present(alert, animated: true, completion: nil)
        }
    }
    
    /// Cancels the registration flow, handing control back to the onboarding coordinator.
    @MainActor private func cancelRegistration() {
        authenticationService.reset()
        callback?(.cancel(.register))
    }
    
    // MARK: - Login
    
    /// Shows the login screen.
    @MainActor private func showLoginScreen() {
        MXLog.debug("[AuthenticationCoordinator] showLoginScreen")
        
        let homeserver = authenticationService.state.homeserver
        let parameters = AuthenticationLoginCoordinatorParameters(navigationRouter: navigationRouter,
                                                                  authenticationService: authenticationService,
                                                                  loginMode: homeserver.preferredLoginMode)
        let coordinator = AuthenticationLoginCoordinator(parameters: parameters)
        coordinator.callback = { [weak self, weak coordinator] result in
            guard let self = self, let coordinator = coordinator else { return }
            self.loginCoordinator(coordinator, didCallbackWith: result)
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

    /// Shows the soft logout screen.
    @MainActor private func showSoftLogoutScreen(_ credentials: MXCredentials) async {
        MXLog.debug("[AuthenticationCoordinator] showSoftLogoutScreen")

        guard let userId = credentials.userId else {
            MXLog.failure("[AuthenticationCoordinator] showSoftLogoutScreen: Missing userId.")
            displayError(message: VectorL10n.errorCommonMessage)
            return
        }

        let store = MXFileStore(credentials: credentials)
        let userDisplayName = await store.displayName(ofUserWithId: userId) ?? ""

        // The backup is now handled by Rust
        let keyBackupNeeded = false

        let softLogoutCredentials = SoftLogoutCredentials(userId: userId,
                                                          homeserverName: credentials.homeServerName() ?? "",
                                                          userDisplayName: userDisplayName,
                                                          deviceId: credentials.deviceId)

        let parameters = AuthenticationSoftLogoutCoordinatorParameters(navigationRouter: navigationRouter,
                                                                       authenticationService: authenticationService,
                                                                       credentials: softLogoutCredentials,
                                                                       keyBackupNeeded: keyBackupNeeded)
        let coordinator = AuthenticationSoftLogoutCoordinator(parameters: parameters)
        coordinator.callback = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let session, let loginPassword):
                self.password = loginPassword
                self.authenticationType = .password
                self.onSessionCreated(session: session, flow: .login)
            case .clearAllData:
                self.callback?(.clearAllData)
            case .continueWithSSO(let provider):
                self.presentSSOAuthentication(for: provider)
            case .fallback:
                self.showFallback(for: .login, deviceId: softLogoutCredentials.deviceId)
            }
        }

        coordinator.start()
        add(childCoordinator: coordinator)

        navigationRouter.setRootModule(coordinator, popCompletion: nil)
    }
    
    /// Displays the next view in the flow based on the result from the registration screen.
    @MainActor private func loginCoordinator(_ coordinator: AuthenticationLoginCoordinator,
                                             didCallbackWith result: AuthenticationLoginCoordinatorResult) {
        switch result {
        case .continueWithSSO(let provider):
            presentSSOAuthentication(for: provider)
        case .success(let session, let loginPassword):
            password = loginPassword
            authenticationType = .password
            onSessionCreated(session: session, flow: .login)
        case .loggedInWithQRCode(let session, let securityCompleted):
            authenticationType = .other
            onSessionCreated(session: session, flow: .login, securityCompleted: securityCompleted)
        case .fallback:
            showFallback(for: .login)
        }
    }
    
    // MARK: - Registration
    
    /// Shows the registration screen.
    @MainActor private func showRegistrationScreen(showReplacementAppBanner: Bool = false) {
        MXLog.debug("[AuthenticationCoordinator] showRegistrationScreen")
        let homeserver = authenticationService.state.homeserver
        let parameters = AuthenticationRegistrationCoordinatorParameters(navigationRouter: navigationRouter,
                                                                         authenticationService: authenticationService,
                                                                         showReplacementAppBanner: showReplacementAppBanner)
        let coordinator = AuthenticationRegistrationCoordinator(parameters: parameters)
        coordinator.callback = { [weak self, weak coordinator] result in
            guard let self = self, let coordinator = coordinator else { return }
            self.registrationCoordinator(coordinator, didCallbackWith: result)
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
    
    /// Displays the next view in the flow based on the result from the registration screen.
    @MainActor private func registrationCoordinator(_ coordinator: AuthenticationRegistrationCoordinator,
                                                    didCallbackWith result: AuthenticationRegistrationCoordinatorResult) {
        switch result {
        case .continueWithSSO(let provider):
            presentSSOAuthentication(for: provider)
        case .completed(let result, let registerPassword):
            password = registerPassword
            authenticationType = .password
            handleRegistrationResult(result)
        case .fallback:
            showFallback(for: .register)
        }
    }
    
    /// Shows the verify email screen.
    @MainActor private func showVerifyEmailScreen(registrationWizard: RegistrationWizard) {
        MXLog.debug("[AuthenticationCoordinator] showVerifyEmailScreen")
        
        let parameters = AuthenticationVerifyEmailCoordinatorParameters(registrationWizard: registrationWizard,
                                                                        homeserver: authenticationService.state.homeserver)
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
    @MainActor private func showTermsScreen(terms: MXLoginTerms?, registrationWizard: RegistrationWizard) {
        MXLog.debug("[AuthenticationCoordinator] showTermsScreen")
        
        let localizedPolicies = terms?.policiesData(forLanguage: Bundle.mxk_language(), defaultLanguage: Bundle.mxk_fallbackLanguage())
        let parameters = AuthenticationTermsCoordinatorParameters(registrationWizard: registrationWizard,
                                                                  localizedPolicies: localizedPolicies ?? [],
                                                                  homeserver: authenticationService.state.homeserver)
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
    
    @MainActor private func showReCaptchaScreen(siteKey: String, registrationWizard: RegistrationWizard) {
        MXLog.debug("[AuthenticationCoordinator] showReCaptchaScreen")
        
        guard let homeserverURL = URL(string: authenticationService.state.homeserver.address) else {
            MXLog.failure("[AuthenticationCoordinator] showReCaptchaScreen: The homeserver address is no longer a valid URL.")
            displayError(message: VectorL10n.errorCommonMessage)
            return
        }
        
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
    @MainActor private func showVerifyMSISDNScreen(registrationWizard: RegistrationWizard) {
        MXLog.debug("[AuthenticationCoordinator] showVerifyMSISDNScreen")

        let parameters = AuthenticationVerifyMsisdnCoordinatorParameters(registrationWizard: registrationWizard,
                                                                         homeserver: authenticationService.state.homeserver)
        let coordinator = AuthenticationVerifyMsisdnCoordinator(parameters: parameters)
        coordinator.callback = { [weak self] result in
            self?.registrationStageDidComplete(with: result)
        }

        coordinator.start()
        add(childCoordinator: coordinator)

        navigationRouter.setRootModule(coordinator, hideNavigationBar: false, animated: true) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
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
    
    // MARK: - Registration Handlers
    /// Determines the next screen to show from the flow result and pushes it.
    @MainActor private func handleRegistrationResult(_ result: RegistrationResult) {
        switch result {
        case .success(let mxSession):
            onSessionCreated(session: mxSession, flow: .register)
        case .flowResponse(let flowResult):
            MXLog.debug("[AuthenticationCoordinator] handleRegistrationResult: Missing stages - \(flowResult.missingStages)")
            
            let homeserver = authenticationService.state.homeserver
            guard let nextStage = homeserver.isMatrixDotOrg ? flowResult.nextUncompletedStageOrdered : flowResult.nextUncompletedStage else {
                MXLog.failure("[AuthenticationCoordinator] There are no remaining stages.")
                return
            }
            
            showStage(nextStage)
        }
    }
    
    @MainActor private func showStage(_ stage: FlowResult.Stage) {
        guard let registrationWizard = authenticationService.registrationWizard else {
            MXLog.failure("[AuthenticationCoordinator] showStage: Missing the RegistrationWizard needed to complete the stage.")
            displayError(message: VectorL10n.errorCommonMessage)
            return
        }
        
        switch stage {
        case .email:
            showVerifyEmailScreen(registrationWizard: registrationWizard)
        case .terms(_, let terms):
            showTermsScreen(terms: terms, registrationWizard: registrationWizard)
        case .reCaptcha(_, let siteKey):
            showReCaptchaScreen(siteKey: siteKey, registrationWizard: registrationWizard)
        case .msisdn:
            showVerifyMSISDNScreen(registrationWizard: registrationWizard)
        case .dummy:
            MXLog.failure("[AuthenticationCoordinator] Attempting to perform the dummy stage.")
        case .other:
            MXLog.failure("[AuthenticationCoordinator] Attempting to perform an unsupported stage.")
            showFallback(for: .register)
        }
    }
    
    /// Handles the creation of a new session following on from a successful authentication.
    @MainActor private func onSessionCreated(session: MXSession, flow: AuthenticationFlow, securityCompleted: Bool = false) {
        self.session = session
        
        guard !securityCompleted else {
            callback?(.didLogin(session: session, authenticationFlow: flow, authenticationType: authenticationType ?? .other))
            callback?(.didComplete)
            return
        }
        
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
        
        callback?(.didLogin(session: session, authenticationFlow: flow, authenticationType: authenticationType ?? .other))
    }
    
    // MARK: - Additional Screens

    private func showFallback(for flow: AuthenticationFlow, deviceId: String? = nil) {
        var url = authenticationService.fallbackURL(for: flow)

        if let deviceId = deviceId {
            //  add deviceId as `device_id` into the url
            guard var urlComponents = URLComponents(string: url.absoluteString) else {
                MXLog.error("[AuthenticationCoordinator] showFallback: could not create url components")
                return
            }
            var queryItems = urlComponents.queryItems ?? []
            queryItems.append(URLQueryItem(name: "device_id", value: deviceId))
            urlComponents.queryItems = queryItems

            if let newUrl = urlComponents.url {
                url = newUrl
            } else {
                MXLog.error("[AuthenticationCoordinator] showFallback: could not create url from components")
                return
            }
        }

        MXLog.debug("[AuthenticationCoordinator] showFallback for: \(flow), url: \(url)")

        guard let fallbackVC = AuthFallBackViewController(url: url.absoluteString) else {
            MXLog.error("[AuthenticationCoordinator] showFallback: could not create fallback view controller")
            return
        }
        fallbackVC.delegate = self
        let navController = RiotNavigationController(rootViewController: fallbackVC)
        navController.navigationBar.topItem?.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                                                 target: self,
                                                                                 action: #selector(dismissFallback))
        navigationRouter.present(navController, animated: true)
    }

    @objc
    private func dismissFallback() {
        MXLog.debug("[AuthenticationCoorrdinator] dismissFallback")

        guard let fallbackNavigationVC = navigationRouter.toPresentable().presentedViewController as? RiotNavigationController else {
            return
        }
        fallbackNavigationVC.dismiss(animated: true)
        authenticationService.reset()
    }
    
    /// Replace the contents of the navigation router with a loading animation.
    private func showLoadingAnimation() {
        let loadingViewController = LaunchLoadingViewController(startupProgress: session?.startupProgress)
        loadingViewController.modalPresentationStyle = .fullScreen
        
        // Replace the navigation stack with the loading animation
        // as there is nothing to navigate back to.
        navigationRouter.setRootModule(loadingViewController)
    }
    
    /// Present the key verification screen modally.
    private func presentCompleteSecurity() {
        guard let session = session else {
            MXLog.error("[AuthenticationCoordinator] presentCompleteSecurity: Unable to present security due to missing session.")
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
        Task {
            await MainActor.run { callback?(.didComplete) }
        }
    }
}

// MARK: - SSO

extension AuthenticationCoordinator: SSOAuthenticationPresenterDelegate {
    /// Presents SSO authentication for the specified identity provider.
    @MainActor private func presentSSOAuthentication(for identityProvider: SSOIdentityProvider) {
        let service = SSOAuthenticationService(homeserverStringURL: authenticationService.state.homeserver.address)
        let presenter = SSOAuthenticationPresenter(ssoAuthenticationService: service)
        presenter.delegate = self
        
        let transactionID = MXTools.generateTransactionId()
        presenter.present(forIdentityProvider: identityProvider, with: transactionID, from: toPresentable(), animated: true)
        
        ssoAuthenticationPresenter = presenter
        ssoTransactionID = transactionID
        authenticationType = .sso(identityProvider)
    }
    
    func ssoAuthenticationPresenter(_ presenter: SSOAuthenticationPresenter, authenticationSucceededWithToken token: String, usingIdentityProvider identityProvider: SSOIdentityProvider?) {
        MXLog.debug("[AuthenticationCoordinator] SSO authentication succeeded.")
        
        guard let loginWizard = authenticationService.loginWizard else {
            MXLog.failure("[AuthenticationCoordinator] The login wizard was requested before getting the login flow.")
            return
        }
        
        Task { await handleLoginToken(token, using: loginWizard) }
    }
    
    func ssoAuthenticationPresenter(_ presenter: SSOAuthenticationPresenter, authenticationDidFailWithError error: Error) {
        MXLog.debug("[AuthenticationCoordinator] SSO authentication failed.")
        
        Task { @MainActor in
            displayError(message: error.localizedDescription)
            ssoAuthenticationPresenter = nil
            ssoTransactionID = nil
            authenticationType = nil
        }
    }
    
    func ssoAuthenticationPresenterDidCancel(_ presenter: SSOAuthenticationPresenter) {
        MXLog.debug("[AuthenticationCoordinator] SSO authentication cancelled.")
        ssoAuthenticationPresenter = nil
        ssoTransactionID = nil
        authenticationType = nil
    }
    
    /// Performs the last step of the login process for a flow that authenticated via SSO.
    @MainActor private func handleLoginToken(_ token: String, using loginWizard: LoginWizard) async {
        do {
            let session = try await loginWizard.login(with: token)
            onSessionCreated(session: session, flow: authenticationService.state.flow)
        } catch {
            MXLog.error("[AuthenticationCoordinator] Login with SSO token failed.")
            displayError(message: error.localizedDescription)
            authenticationType = nil
        }
        
        ssoAuthenticationPresenter = nil
        ssoTransactionID = nil
    }
}

// MARK: - AuthenticationServiceDelegate
extension AuthenticationCoordinator: AuthenticationServiceDelegate {
    
    func authenticationService(_ service: AuthenticationService, needsPromptFor unrecognizedCertificate: Data?, completion: @escaping (Bool) -> Void) {
        guard let certificate = unrecognizedCertificate else {
            completion(false)
            return
        }
        
        Task {
            let trusted = await self.displayUnrecognizedCertificateAlert(for: certificate)
            completion(trusted)
        }
    }
    
    func authenticationService(_ service: AuthenticationService, didReceive ssoLoginToken: String, with transactionID: String) -> Bool {
        guard let presenter = ssoAuthenticationPresenter, transactionID == ssoTransactionID else {
            Task { await displayError(message: VectorL10n.errorCommonMessage) }
            return false
        }
        
        guard let loginWizard = authenticationService.loginWizard else {
            MXLog.failure("[AuthenticationCoordinator] The login wizard was requested before getting the login flow.")
            return false
        }
        
        Task {
            await handleLoginToken(ssoLoginToken, using: loginWizard)
            await MainActor.run { presenter.dismiss(animated: true, completion: nil) }
        }
        
        return true
    }

    func authenticationService(_ service: AuthenticationService, didUpdateStateWithLink link: UniversalLink) {
        if link.pathParams.first == "register" {
            callback?(.cancel(.register))
        } else {
            callback?(.cancel(.login))
        }
        successIndicator = indicatorPresenter.present(.success(label: VectorL10n.done))
    }
}

// MARK: - KeyVerificationCoordinatorDelegate
extension AuthenticationCoordinator: KeyVerificationCoordinatorDelegate {
    func keyVerificationCoordinatorDidComplete(_ coordinator: KeyVerificationCoordinatorType, otherUserId: String, otherDeviceId: String) {
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
    func update(authenticationFlow: AuthenticationFlow) {
        // unused
    }
}

// MARK: - AuthFallBackViewControllerDelegate
extension AuthenticationCoordinator: AuthFallBackViewControllerDelegate {
    func authFallBackViewController(_ authFallBackViewController: AuthFallBackViewController,
                                    didLoginWith loginResponse: MXLoginResponse) {
        let credentials = MXCredentials(loginResponse: loginResponse, andDefaultCredentials: nil)
        let client = MXRestClient(credentials: credentials)
        guard let session = MXSession(matrixRestClient: client) else {
            MXLog.failure("[AuthenticationCoordinator] authFallBackViewController:didLogin: session could not be created")
            return
        }
        authenticationType = .other
        Task { await onSessionCreated(session: session, flow: authenticationService.state.flow) }
    }

    func authFallBackViewControllerDidClose(_ authFallBackViewController: AuthFallBackViewController) {
        dismissFallback()
    }
}
