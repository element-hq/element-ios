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
        self.router = router ?? NavigationRouter(navigationController: RiotNavigationController())
        self.softLogoutCredentials = softLogoutCredentials
    }
}

@objcMembers
final class OnboardingCoordinator: NSObject, Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
        
    private let parameters: OnboardingCoordinatorParameters
    /// The external registration parameters for AuthenticationViewController.
    private var externalRegistrationParameters: [AnyHashable: Any]?
    private var customHomeserver: String?
    private var customIdentityServer: String?
    
//    private var currentPresentable: Presentable?
    
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
        // TODO: Manage a separate flow for soft logout
        if #available(iOS 14.0, *), parameters.softLogoutCredentials == nil {
            showSplashScreen()
            preloadAuthentication()
        } else {
            showAuthenticationScreen(isPartOfFlow: false)
        }
    }
    
    func toPresentable() -> UIViewController {
        navigationRouter.toPresentable()
    }
    
    func update(externalRegistrationParameters: [AnyHashable: Any]) {
        self.externalRegistrationParameters = externalRegistrationParameters
        authenticationCoordinator?.update(externalRegistrationParameters: externalRegistrationParameters)
    }
    
    func showCustomHomeserver(_ homeserver: String?, andIdentityServer identityServer: String?) {
        self.customHomeserver = homeserver
        self.customIdentityServer = identityServer
        authenticationCoordinator?.showCustomHomeserver(homeserver, andIdentityServer: identityServer)
    }
    
    func continueSSOLogin(withToken loginToken: String, transactionID: String) -> Bool {
        guard let authenticationCoordinator = authenticationCoordinator else { return false }
        return authenticationCoordinator.continueSSOLogin(withToken: loginToken, transactionID: transactionID)
    }
    
    // MARK: - Private
    
    @available(iOS 14.0, *)
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
    
    private func splashScreenCoordinator(_ coordinator: OnboardingSplashScreenCoordinator, didCompleteWith result: OnboardingSplashScreenViewModelResult) {
        splashScreenResult = result
        showAuthenticationScreen(isPartOfFlow: true)
    }
    
    private func preloadAuthentication() {
        AuthenticationCoordinator.preload()
    }
    
    private func showAuthenticationScreen(isPartOfFlow: Bool) {
        guard authenticationCoordinator == nil else { return }
        
        MXLog.debug("[OnboardingCoordinator] showAuthenticationScreen")
        
        let parameters = AuthenticationCoordinatorParameters(authenticationType: splashScreenResult == .register ? MXKAuthenticationTypeRegister : MXKAuthenticationTypeLogin,
                                                             externalRegistrationParameters: externalRegistrationParameters,
                                                             softLogoutCredentials: parameters.softLogoutCredentials,
                                                             isPartOfFlow: isPartOfFlow)
        
        let coordinator = AuthenticationCoordinator(parameters: parameters)
        coordinator.completion = { [weak self, weak coordinator] result in
            guard let self = self, let coordinator = coordinator else { return }
            switch result {
            case .navigateBack:
                self.navigationRouter.popModule(animated: true)
                self.remove(childCoordinator: coordinator)
            case .success:
                self.authenticationCoordinatorDidComplete(coordinator)
            }
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
            self.navigationRouter.push(coordinator, animated: true, popCompletion: nil)
        }
    }
    
    private func authenticationCoordinatorDidComplete(_ coordinator: AuthenticationCoordinator) {
        completion?()
    }
}
