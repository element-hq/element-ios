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
    #warning("This might be removable when SSO comes through the AuthenticationService?")
    /// A boolean to prevent authentication being shown when already in progress.
    private var isShowingLegacyAuthentication = false
    
    // MARK: Screen results
    private var splashScreenResult: OnboardingSplashScreenViewModelResult?
    private var useCaseResult: OnboardingUseCaseViewModelResult?
    private var authenticationType: MXKAuthenticationType?
    private var session: MXSession?
    /// A place to store the image selected in the avatar screen until it has been saved.
    private var selectedAvatar: UIImage?
    
    private var shouldShowDisplayNameScreen = false
    private var shouldShowAvatarScreen = false
    
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
        let authenticationParameters = LegacyAuthenticationCoordinatorParameters(navigationRouter: parameters.router, canPresentAdditionalScreens: false)
        authenticationCoordinator = LegacyAuthenticationCoordinator(parameters: authenticationParameters)
        
        super.init()
    }    
    
    // MARK: - Public
    
    func start() {
        // TODO: Manage a separate flow for soft logout that just uses AuthenticationCoordinator
        if #available(iOS 14.0, *), parameters.softLogoutCredentials == nil, BuildSettings.authScreenShowRegister {
            showSplashScreen()
        } else {
            showLegacyAuthenticationScreen()
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
        guard isShowingLegacyAuthentication else { return false }
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
            showLegacyAuthenticationScreen()
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
    @available(iOS 14.0, *)
    private func useCaseSelectionCoordinator(_ coordinator: OnboardingUseCaseSelectionCoordinator, didCompleteWith result: OnboardingUseCaseViewModelResult) {
        useCaseResult = result
        
        guard BuildSettings.onboardingEnableNewAuthenticationFlow else {
            showLegacyAuthenticationScreen()
            return
        }
        
        if result == .customServer {
            beginAuthentication(with: .selectServerForRegistration)
        } else {
            beginAuthentication(with: .registration)
        }
    }
    
    // MARK: - Authentication
    
    /// Show the authentication flow, starting at the specified initial screen.
    @available(iOS 14.0, *)
    private func beginAuthentication(with initialScreen: AuthenticationCoordinator.EntryPoint) {
        MXLog.debug("[OnboardingCoordinator] beginAuthentication")
        
        let parameters = AuthenticationCoordinatorParameters(navigationRouter: navigationRouter,
                                                             initialScreen: initialScreen,
                                                             canPresentAdditionalScreens: false)
        let coordinator = AuthenticationCoordinator(parameters: parameters)
        coordinator.completion = { [weak self, weak coordinator] result in
            guard let self = self, let coordinator = coordinator else { return }
            
            switch result {
            case .didLogin(let session, let authenticationType):
                self.authenticationCoordinator(coordinator, didLoginWith: session, and: authenticationType)
            case .didComplete:
                self.authenticationCoordinatorDidComplete(coordinator)
            }
        }
        
        add(childCoordinator: coordinator)
        coordinator.start()
    }
    
    /// Show the legacy authentication screen. Any parameters that have been set in previous screens are be applied.
    private func showLegacyAuthenticationScreen() {
        guard !isShowingLegacyAuthentication else { return }
        
        MXLog.debug("[OnboardingCoordinator] showLegacyAuthenticationScreen")
        
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
        
        coordinator.customServerFieldsVisible = useCaseResult == .customServer
        
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
                self?.isShowingLegacyAuthentication = false
            }
        }
        isShowingLegacyAuthentication = true
    }
    
    /// Displays the next view in the flow after the authentication screens,
    /// whilst crypto and the rest of the app is launching in the background.
    private func authenticationCoordinator(_ coordinator: AuthenticationCoordinatorProtocol,
                                           didLoginWith session: MXSession,
                                           and authenticationType: MXKAuthenticationType) {
        self.session = session
        self.authenticationType = authenticationType
        
        // Check whether another screen should be shown.
        if #available(iOS 14.0, *) {
            if authenticationType == .register,
               let userId = session.credentials.userId,
               let userSession = UserSessionsService.shared.userSession(withUserId: userId) {
                // If personalisation is to be shown, check that the homeserver supports it otherwise show the congratulations screen
                if BuildSettings.onboardingShowAccountPersonalization {
                    checkHomeserverCapabilities(for: userSession)
                    return
                } else {
                    showCongratulationsScreen(for: userSession)
                    return
                }
            } else if Analytics.shared.shouldShowAnalyticsPrompt {
                showAnalyticsPrompt(for: session)
                return
            }
        }
        
        // Otherwise onboarding is finished.
        onboardingFinished = true
        completeIfReady()
    }
    
    /// Checks the capabilities of the user's homeserver in order to determine
    /// whether or not the display name and avatar can be updated.
    ///
    /// Once complete this method will start the post authentication flow automatically.
    @available(iOS 14.0, *)
    private func checkHomeserverCapabilities(for userSession: UserSession) {
        userSession.matrixSession.matrixRestClient.capabilities { [weak self] capabilities in
            guard let self = self else { return }
            self.shouldShowDisplayNameScreen = capabilities?.setDisplayName?.isEnabled == true
            self.shouldShowAvatarScreen = capabilities?.setAvatarUrl?.isEnabled == true
            
            self.beginPostAuthentication(for: userSession)
        } failure: { [weak self] _ in
            MXLog.warning("[OnboardingCoordinator] Homeserver capabilities not returned. Skipping personalisation")
            self?.beginPostAuthentication(for: userSession)
        }
    }
    
    /// Completes the onboarding flow if possible, otherwise waits for any remaining screens.
    private func authenticationCoordinatorDidComplete(_ coordinator: AuthenticationCoordinatorProtocol) {
        isShowingLegacyAuthentication = false
        
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
    
    /// Starts the part of the flow that comes after authentication for new users.
    @available(iOS 14.0, *)
    private func beginPostAuthentication(for userSession: UserSession) {
        showCongratulationsScreen(for: userSession)
    }
    
    /// Show the congratulations screen for new users. The screen will be configured based on the homeserver's capabilities.
    @available(iOS 14.0, *)
    private func showCongratulationsScreen(for userSession: UserSession) {
        MXLog.debug("[OnboardingCoordinator] showCongratulationsScreen")
        
        let parameters = OnboardingCongratulationsCoordinatorParameters(userSession: userSession,
                                                                        personalizationDisabled: !shouldShowDisplayNameScreen && !shouldShowAvatarScreen)
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
    
    /// Displays the next view in the flow after the congratulations screen.
    @available(iOS 14.0, *)
    private func congratulationsCoordinator(_ coordinator: OnboardingCongratulationsCoordinator, didCompleteWith result: OnboardingCongratulationsCoordinatorResult) {
        switch result {
        case .personalizeProfile(let userSession):
            if shouldShowDisplayNameScreen {
                showDisplayNameScreen(for: userSession)
                return
            } else if shouldShowAvatarScreen {
                showAvatarScreen(for: userSession)
                return
            } else if Analytics.shared.shouldShowAnalyticsPrompt {
                showAnalyticsPrompt(for: userSession.matrixSession)
                return
            }
        case .takeMeHome(let userSession):
            if Analytics.shared.shouldShowAnalyticsPrompt {
                showAnalyticsPrompt(for: userSession.matrixSession)
                return
            }
        }
        
        onboardingFinished = true
        completeIfReady()
    }
    
    /// Show the display name personalization screen for new users using the supplied user session.
    @available(iOS 14.0, *)
    private func showDisplayNameScreen(for userSession: UserSession) {
        MXLog.debug("[OnboardingCoordinator]: showDisplayNameScreen")
        
        let parameters = OnboardingDisplayNameCoordinatorParameters(userSession: userSession)
        let coordinator = OnboardingDisplayNameCoordinator(parameters: parameters)
        
        coordinator.completion = { [weak self, weak coordinator] userSession in
            guard let self = self, let coordinator = coordinator else { return }
            self.displayNameCoordinator(coordinator, didCompleteWith: userSession)
        }
        
        add(childCoordinator: coordinator)
        coordinator.start()
        
        navigationRouter.setRootModule(coordinator, hideNavigationBar: false, animated: true) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }
    
    /// Displays the next view in the flow after the display name screen.
    @available(iOS 14.0, *)
    private func displayNameCoordinator(_ coordinator: OnboardingDisplayNameCoordinator, didCompleteWith userSession: UserSession) {
        if shouldShowAvatarScreen {
            showAvatarScreen(for: userSession)
        } else {
            showCelebrationScreen(for: userSession)
        }
    }
    
    /// Show the avatar personalization screen for new users using the supplied user session.
    @available(iOS 14.0, *)
    private func showAvatarScreen(for userSession: UserSession) {
        MXLog.debug("[OnboardingCoordinator]: showAvatarScreen")
        
        let parameters = OnboardingAvatarCoordinatorParameters(userSession: userSession, avatar: selectedAvatar)
        let coordinator = OnboardingAvatarCoordinator(parameters: parameters)
        
        coordinator.completion = { [weak self, weak coordinator] result in
            guard let self = self, let coordinator = coordinator else { return }
            
            switch result {
            case .selectedAvatar(let image):
                // Store the avatar so that if the user navigates back to the display name
                // screen we can show the chosen image again when the avatar screen is pushed.
                self.selectedAvatar = image
            case .complete(let userSession):
                self.avatarCoordinator(coordinator, didCompleteWith: userSession)
            }
        }
        
        add(childCoordinator: coordinator)
        coordinator.start()
        
        if navigationRouter.modules.isEmpty || !shouldShowDisplayNameScreen {
            navigationRouter.setRootModule(coordinator, hideNavigationBar: false, animated: true) { [weak self] in
                self?.remove(childCoordinator: coordinator)
            }
        } else {
            navigationRouter.push(coordinator, animated: true) { [weak self] in
                self?.remove(childCoordinator: coordinator)
            }
        }
    }
    
    /// Displays the next view in the flow after the avatar screen.
    @available(iOS 14.0, *)
    private func avatarCoordinator(_ coordinator: OnboardingAvatarCoordinator, didCompleteWith userSession: UserSession) {
        showCelebrationScreen(for: userSession)
        
        // It is no longer possible to navigate backwards so forget the selected avatar
        selectedAvatar = nil
    }
    
    @available(iOS 14.0, *)
    private func showCelebrationScreen(for userSession: UserSession) {
        MXLog.debug("[OnboardingCoordinator] showCelebrationScreen")
        
        let parameters = OnboardingCelebrationCoordinatorParameters(userSession: userSession)
        let coordinator = OnboardingCelebrationCoordinator(parameters: parameters)
        
        coordinator.completion = { [weak self, weak coordinator] userSession in
            guard let self = self, let coordinator = coordinator else { return }
            self.celebrationCoordinator(coordinator, didCompleteWith: userSession)
        }
        
        add(childCoordinator: coordinator)
        coordinator.start()
        
        navigationRouter.setRootModule(coordinator, hideNavigationBar: true, animated: true) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }
    
    @available(iOS 14.0, *)
    private func celebrationCoordinator(_ coordinator: OnboardingCelebrationCoordinator, didCompleteWith userSession: UserSession) {
        if Analytics.shared.shouldShowAnalyticsPrompt {
            showAnalyticsPrompt(for: userSession.matrixSession)
            return
        }
        
        onboardingFinished = true
        completeIfReady()
    }
    
    /// Shows the analytics prompt for the supplied session.
    ///
    /// Check `Analytics.shared.shouldShowAnalyticsPrompt` before calling this method.
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
    
    /// Displays the next view in the flow after the analytics screen.
    private func analyticsPromptCoordinatorDidComplete(_ coordinator: AnalyticsPromptCoordinator) {
        onboardingFinished = true
        completeIfReady()
    }
    
    // MARK: - Finished
    
    /// Calls the coordinator's completion handler if both `onboardingFinished` and `authenticationFinished`
    /// are true. Otherwise displays any pending screens and waits to be called again.
    private func completeIfReady() {
        guard onboardingFinished else {
            MXLog.debug("[OnboardingCoordinator] Delaying onboarding completion until all screens have been shown.")
            return
        }
        
        guard authenticationFinished else {
            MXLog.debug("[OnboardingCoordinator] Allowing LegacyAuthenticationCoordinator to display any remaining screens.")
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
