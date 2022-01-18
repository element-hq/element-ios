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
final class OnboardingCoordinator: NSObject, Coordinator, Presentable {
    
    // MARK: - Constants
    static let maxContentWidth: CGFloat = 600
    static let maxContentHeight: CGFloat = 750
    
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
    
    private var navigationRouter: NavigationRouterType {
        parameters.router
    }
    private var splashScreenResult: OnboardingSplashScreenViewModelResult?
    private weak var authenticationCoordinator: AuthenticationCoordinator?
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: (() -> Void)?
    
    // MARK: - Setup
    
    init(parameters: OnboardingCoordinatorParameters) {
        self.parameters = parameters
        super.init()
    }    
    
    // MARK: - Public
    
    func start() {
        // TODO: Manage a separate flow for soft logout that just uses AuthenticationCoordinator
        if #available(iOS 14.0, *), parameters.softLogoutCredentials == nil, BuildSettings.authScreenShowRegister {
            showSplashScreen()
            preloadAuthentication()
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
        authenticationCoordinator?.update(externalRegistrationParameters: externalRegistrationParameters)
    }
    
    /// Set up the authentication screen with the specified homeserver and/or identity server.
    func showCustomHomeserver(_ homeserver: String?, andIdentityServer identityServer: String?) {
        self.customHomeserver = homeserver
        self.customIdentityServer = identityServer
        authenticationCoordinator?.showCustomHomeserver(homeserver, andIdentityServer: identityServer)
    }
    
    /// When SSO login succeeded, when SFSafariViewController is used, continue login with success parameters.
    func continueSSOLogin(withToken loginToken: String, transactionID: String) -> Bool {
        guard let authenticationCoordinator = authenticationCoordinator else { return false }
        return authenticationCoordinator.continueSSOLogin(withToken: loginToken, transactionID: transactionID)
    }
    
    // MARK: - Private
    
    @available(iOS 14.0, *)
    /// Show the onboarding splash screen as the root module in the flow.
    private func showSplashScreen() {
        let coordinatorParameters = OnboardingSplashScreenCoordinatorParameters()
        let coordinator = OnboardingSplashScreenCoordinator(parameters: coordinatorParameters)
        coordinator.completion = { [weak self, weak coordinator] result in
            guard let self = self, let coordinator = coordinator else { return }
            self.splashScreenCoordinator(coordinator, didCompleteWith: result)
        }
        
        coordinator.start()
        add(childCoordinator: coordinator)
        
        self.navigationRouter.setRootModule(coordinator, popCompletion: nil)
    }
    
    /// Displays the next view in the flow after the splash screen.
    private func splashScreenCoordinator(_ coordinator: OnboardingSplashScreenCoordinator, didCompleteWith result: OnboardingSplashScreenViewModelResult) {
        splashScreenResult = result
        showAuthenticationScreen()
    }
    
    /// Preload the authentication view controller to avoid a delay during its presentation
    private func preloadAuthentication() {
        AuthenticationCoordinator.preload()
    }
    
    /// Show the authentication screen. Any parameters that have been set in previous screens are be applied.
    private func showAuthenticationScreen() {
        guard authenticationCoordinator == nil else { return }
        
        MXLog.debug("[OnboardingCoordinator] showAuthenticationScreen")
        
        let parameters = AuthenticationCoordinatorParameters(authenticationType: splashScreenResult == .register ? MXKAuthenticationTypeRegister : MXKAuthenticationTypeLogin,
                                                             externalRegistrationParameters: externalRegistrationParameters,
                                                             softLogoutCredentials: parameters.softLogoutCredentials)
        
        let coordinator = AuthenticationCoordinator(parameters: parameters)
        coordinator.completion = { [weak self, weak coordinator] in
            guard let self = self, let coordinator = coordinator else { return }
            self.authenticationCoordinatorDidComplete(coordinator)
        }
        
        coordinator.start()
        add(childCoordinator: coordinator)
        authenticationCoordinator = coordinator
        
        if customHomeserver != nil || customIdentityServer != nil {
            coordinator.showCustomHomeserver(customHomeserver, andIdentityServer: customIdentityServer)
        }
        
        if self.navigationRouter.modules.isEmpty {
            self.navigationRouter.setRootModule(coordinator, popCompletion: nil)
        } else {
            self.navigationRouter.push(coordinator, animated: true) { [weak self] in
                self?.remove(childCoordinator: coordinator)
            }
        }
    }
    
    /// Displays the next view in the flow after the authentication screen.
    private func authenticationCoordinatorDidComplete(_ coordinator: AuthenticationCoordinator) {
        completion?()
    }
}
