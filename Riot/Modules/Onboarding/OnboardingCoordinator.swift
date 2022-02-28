// File created from FlowTemplate
// $ createRootCoordinator.sh Onboarding/SplashScreen Onboarding OnboardingSplashScreen
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

/// OnboardingCoordinator input parameters
struct OnboardingCoordinatorParameters {
                
    /// The navigation router that manage physical navigation
    let router: NavigationRouterType
    /// The credentials to use if a soft logout has taken place.
    let softLogoutCredentials: MXCredentials?
    
    init(router: NavigationRouterType? = nil,
         softLogoutCredentials: MXCredentials? = nil) {
        self.router = router ?? NavigationRouter(navigationController: RiotNavigationController(isLockedToPortraitOnPhone: true))
        self.softLogoutCredentials = softLogoutCredentials
    }
}

@objcMembers
/// A coordinator to manage the full onboarding flow with pre-auth screens, authentication and setup screens once signed in.
final class OnboardingCoordinator: NSObject, OnboardingCoordinatorProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
        
    private let parameters: OnboardingCoordinatorParameters
    // TODO: these can likely be consolidated using an additional authType.
    /// The any registration parameters for AuthenticationViewController from a server provisioning link.
    private var externalRegistrationParameters: [AnyHashable: Any]?
    /// A custom homeserver to be shown when logging in.
    private var customHomeserver: String?
    /// A custom identity server to be used once logged in.
    private var customIdentityServer: String?
    
    // MARK: Navigation State
    private var navigationRouter: NavigationRouterType {
        parameters.router
    }
    // Keep a strong ref as we need to init authVC early to preload its view
    private let authenticationCoordinator: AuthenticationCoordinatorProtocol
    /// A boolean to prevent authentication being shown when already in progress.
    private var isShowingAuthentication = false
    
    // MARK: Screen results
    private var splashScreenResult: OnboardingSplashScreenViewModelResult?
    private var useCaseResult: OnboardingUseCaseViewModelResult?
    private var authenticationType: MXKAuthenticationType?
    private var session: MXSession?
    
    /// Whether all of the onboarding steps have been completed or not. `false` if there are more screens to be shown.
    private var onboardingFinished = false
    /// Whether authentication is complete. `true` once authenticated, verified and the app is ready to be shown.
    private var authenticationFinished = false
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: (() -> Void)?
    
    // MARK: - Setup
    
    init(parameters: OnboardingCoordinatorParameters) {
        self.parameters = parameters
        
        // Preload the authVC (it is *really* slow to load in realtime)
        let authenticationParameters = AuthenticationCoordinatorParameters(navigationRouter: parameters.router, canPresentAdditionalScreens: false)
        authenticationCoordinator = AuthenticationCoordinator(parameters: authenticationParameters)
        
        super.init()
    }    
    
    // MARK: - Public
    
    func start() {
        // TODO: Manage a separate flow for soft logout that just uses AuthenticationCoordinator
        if #available(iOS 14.0, *), parameters.softLogoutCredentials == nil, BuildSettings.authScreenShowRegister {
            showSplashScreen()
        } else {
            showAuthenticationScreen()
        }
    }
    
    func toPresentable() -> UIViewController {
        navigationRouter.toPresentable()
    }
    
    /// Force a registration process based on a predefined set of parameters from a server provisioning link.
    /// For more information see `AuthenticationViewController.externalRegistrationParameters`.
    func update(externalRegistrationParameters: [AnyHashable: Any]) {
        self.externalRegistrationParameters = externalRegistrationParameters
        authenticationCoordinator.update(externalRegistrationParameters: externalRegistrationParameters)
    }
    
    /// Set up the authentication screen with the specified homeserver and/or identity server.
    func updateHomeserver(_ homeserver: String?, andIdentityServer identityServer: String?) {
        self.customHomeserver = homeserver
        self.customIdentityServer = identityServer
        authenticationCoordinator.updateHomeserver(homeserver, andIdentityServer: identityServer)
    }
    
    /// When SSO login succeeded, when SFSafariViewController is used, continue login with success parameters.
    func continueSSOLogin(withToken loginToken: String, transactionID: String) -> Bool {
        guard isShowingAuthentication else { return false }
        return authenticationCoordinator.continueSSOLogin(withToken: loginToken, transactionID: transactionID)
    }
    
    // MARK: - Pre-Authentication
    
    @available(iOS 14.0, *)
    /// Show the onboarding splash screen as the root module in the flow.
    private func showSplashScreen() {
        MXLog.debug("[OnboardingCoordinator] showSplashScreen")
        
        let coordinator = OnboardingSplashScreenCoordinator()
        coordinator.completion = { [weak self, weak coordinator] result in
            guard let self = self, let coordinator = coordinator else { return }
            self.splashScreenCoordinator(coordinator, didCompleteWith: result)
        }
        
        coordinator.start()
        add(childCoordinator: coordinator)
        
        navigationRouter.setRootModule(coordinator, popCompletion: nil)
    }
    
    @available(iOS 14.0, *)
    /// Displays the next view in the flow after the splash screen.
    private func splashScreenCoordinator(_ coordinator: OnboardingSplashScreenCoordinator, didCompleteWith result: OnboardingSplashScreenViewModelResult) {
        splashScreenResult = result
        
        // Set the auth type early to allow network requests to finish during display of the use case screen.
        authenticationCoordinator.update(authenticationType: result.mxkAuthenticationType)
        
        switch result {
        case .register:
            showUseCaseSelectionScreen()
        case .login:
            showAuthenticationScreen()
        }
    }
    
    @available(iOS 14.0, *)
    /// Show the use case screen for new users.
    private func showUseCaseSelectionScreen() {
        MXLog.debug("[OnboardingCoordinator] showUseCaseSelectionScreen")
        
        let coordinator = OnboardingUseCaseSelectionCoordinator()
        coordinator.completion = { [weak self, weak coordinator] result in
            guard let self = self, let coordinator = coordinator else { return }
            self.useCaseSelectionCoordinator(coordinator, didCompleteWith: result)
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
    
    /// Displays the next view in the flow after the use case screen.
    private func useCaseSelectionCoordinator(_ coordinator: OnboardingUseCaseSelectionCoordinator, didCompleteWith result: OnboardingUseCaseViewModelResult) {
        useCaseResult = result
        showAuthenticationScreen()
    }
    
    // MARK: - Authentication
    
    /// Show the authentication screen. Any parameters that have been set in previous screens are be applied.
    private func showAuthenticationScreen() {
        guard !isShowingAuthentication else { return }
        
        MXLog.debug("[OnboardingCoordinator] showAuthenticationScreen")
        
        let coordinator = authenticationCoordinator
        coordinator.completion = { [weak self, weak coordinator] result in
            guard let self = self, let coordinator = coordinator else { return }
            
            switch result {
            case .didLogin(let session, let authenticationType):
                self.authenticationCoordinator(coordinator, didLoginWith: session, and: authenticationType)
            case .didComplete:
                self.authenticationCoordinatorDidComplete(coordinator)
            }
            
        }
        
        // Due to needing to preload the authVC, this breaks the Coordinator init/start pattern.
        // This can be re-assessed once we re-write a native flow for authentication.
        
        if let externalRegistrationParameters = externalRegistrationParameters {
            coordinator.update(externalRegistrationParameters: externalRegistrationParameters)
        }
        
        if useCaseResult == .customServer {
            coordinator.showCustomServer()
        }
        
        if let softLogoutCredentials = parameters.softLogoutCredentials {
            coordinator.update(softLogoutCredentials: softLogoutCredentials)
        }
        
        coordinator.start()
        add(childCoordinator: coordinator)
        
        if customHomeserver != nil || customIdentityServer != nil {
            coordinator.updateHomeserver(customHomeserver, andIdentityServer: customIdentityServer)
        }
        
        if navigationRouter.modules.isEmpty {
            navigationRouter.setRootModule(coordinator, popCompletion: nil)
        } else {
            navigationRouter.push(coordinator, animated: true) { [weak self] in
                self?.remove(childCoordinator: coordinator)
                self?.isShowingAuthentication = false
            }
        }
        isShowingAuthentication = true
    }
    
    /// Displays the next view in the flow after the authentication screen,
    /// whilst crypto and the rest of the app is launching in the background.
    private func authenticationCoordinator(_ coordinator: AuthenticationCoordinatorProtocol,
                                           didLoginWith session: MXSession,
                                           and authenticationType: MXKAuthenticationType) {
        self.session = session
        self.authenticationType = authenticationType
        
        // May need to move the spinner and key verification up to here in order to coordinate properly.
        
        // Check whether another screen should be shown.
        if #available(iOS 14.0, *) {
            if authenticationType == .register, let userId = session.credentials.userId, BuildSettings.onboardingShowAccountPersonalisation {
                showCongratulationsScreen(userId: userId)
                return
            } else if Analytics.shared.shouldShowAnalyticsPrompt {
                showAnalyticsPrompt(for: session)
                return
            }
        }
        
        // Otherwise onboarding is finished.
        onboardingFinished = true
        completeIfReady()
    }
    
    /// Displays the next view in the flow after the authentication screen.
    private func authenticationCoordinatorDidComplete(_ coordinator: AuthenticationCoordinatorProtocol) {
        isShowingAuthentication = false
        
        // Handle the chosen use case where applicable
        if authenticationType == .register,
           let useCase = useCaseResult?.userSessionPropertyValue,
           let userSession = UserSessionsService.shared.mainUserSession {
            // Store the value in the user's session
            userSession.userProperties.useCase = useCase
            
            // Update the analytics user properties with the use case
            Analytics.shared.updateUserProperties(ftueUseCase: useCase)
        }
        
        // This method is only called when the app is ready so we can complete if finished
        authenticationFinished = true
        completeIfReady()
    }
    
    // MARK: - Post-Authentication
    
    @available(iOS 14.0, *)
    private func showCongratulationsScreen(userId: String) {
        MXLog.debug("[OnboardingCoordinator] showCongratulationsScreen")
        
        let parameters = OnboardingCongratulationsCoordinatorParameters(userId: userId)
        let coordinator = OnboardingCongratulationsCoordinator(parameters: parameters)
        
        coordinator.completion = { [weak self, weak coordinator] result in
            guard let self = self, let coordinator = coordinator else { return }
            self.congratulationsCoordinator(coordinator, didCompleteWith: result)
        }
        
        add(childCoordinator: coordinator)
        coordinator.start()
        
        // Navigating back doesn't make any sense now, so replace the whole stack.
        navigationRouter.setRootModule(coordinator, hideNavigationBar: true, animated: true) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }
    
    @available(iOS 14.0, *)
    private func congratulationsCoordinator(_ coordinator: OnboardingCongratulationsCoordinator, didCompleteWith result: OnboardingCongratulationsViewModelResult) {
        if let session = session {
            switch result {
            case .personaliseProfile:
                // TODO: Profile screens here instead.
                if Analytics.shared.shouldShowAnalyticsPrompt {
                    showAnalyticsPrompt(for: session)
                    return
                }
            case .takeMeHome:
                if Analytics.shared.shouldShowAnalyticsPrompt {
                    showAnalyticsPrompt(for: session)
                    return
                }
            }
        }
        
        onboardingFinished = true
        completeIfReady()
    }
    
    @available(iOS 14.0, *)
    private func showAnalyticsPrompt(for session: MXSession) {
        MXLog.debug("[OnboardingCoordinator]: Invite the user to send analytics")
        
        let parameters = AnalyticsPromptCoordinatorParameters(session: session)
        let coordinator = AnalyticsPromptCoordinator(parameters: parameters)
        
        coordinator.completion = { [weak self, weak coordinator] in
            guard let self = self, let coordinator = coordinator else { return }
            self.analyticsPromptCoordinatorDidComplete(coordinator)
        }
        
        add(childCoordinator: coordinator)
        coordinator.start()
        
        // TODO: Re-asses replacing the stack based on the previous screen once the whole flow is implemented
        navigationRouter.setRootModule(coordinator, hideNavigationBar: true, animated: true) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }
    
    private func analyticsPromptCoordinatorDidComplete(_ coordinator: AnalyticsPromptCoordinator) {
        onboardingFinished = true
        completeIfReady()
    }
    
    // MARK: - Finished
    
    private func completeIfReady() {
        guard onboardingFinished else {
            MXLog.debug("[OnboardingCoordinator] Delaying onboarding completion until all screens have been shown.")
            return
        }
        
        guard authenticationFinished else {
            MXLog.debug("[OnboardingCoordinator] Allowing AuthenticationCoordinator to display any remaining screens.")
            authenticationCoordinator.presentPendingScreensIfNecessary()
            return
        }
        
        completion?()
    }
}

// MARK: - Helpers

extension OnboardingSplashScreenViewModelResult {
    /// The result converted into the MatrixKit authentication type to use.
    var mxkAuthenticationType: MXKAuthenticationType {
        switch self {
        case .login:
            return .login
        case .register:
            return .register
        }
    }
}

extension OnboardingUseCaseViewModelResult {
    /// The result converted into the type stored in the user session.
    var userSessionPropertyValue: UserSessionProperties.UseCase? {
        switch self {
        case .personalMessaging:
            return .personalMessaging
        case .workMessaging:
            return .workMessaging
        case .communityMessaging:
            return .communityMessaging
        case .skipped:
            return .skipped
        case .customServer:
            return nil
        }
    }
}
