// File created from FlowTemplate
// $ createRootCoordinator.sh Reauthentication Reauthentication
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

enum ReauthenticationCoordinatorError: Error {
    case failToBuildPasswordParameters
}

@objcMembers
final class ReauthenticationCoordinator: ReauthenticationCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: ReauthenticationCoordinatorParameters
    private let userInteractiveAuthenticationService: UserInteractiveAuthenticationService
    private let authenticationParametersBuilder: AuthenticationParametersBuilder
    private let uiaViewControllerFactory: UserInteractiveAuthenticationViewControllerFactory
    
    private var ssoAuthenticationPresenter: SSOAuthenticationPresenter?
    
    private var authenticationSession: SSOAuthentificationSessionProtocol?
    
    private var presentingViewController: UIViewController {
        return self.parameters.presenter.toPresentable()
    }
    
    private weak var passwordViewController: UIViewController?
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: ReauthenticationCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(parameters: ReauthenticationCoordinatorParameters) {
        self.parameters = parameters
        self.userInteractiveAuthenticationService = UserInteractiveAuthenticationService(session: parameters.session)
        self.authenticationParametersBuilder = AuthenticationParametersBuilder()
        self.uiaViewControllerFactory = UserInteractiveAuthenticationViewControllerFactory()
    }    
    
    // MARK: - Public methods
    
    func start() {
        if let authenticatedEndpointRequest = self.parameters.authenticatedEndpointRequest {
            self.start(with: authenticatedEndpointRequest)
        } else if let authenticationSession = self.parameters.authenticationSession {
            self.start(with: authenticationSession)
        } else {
            fatalError("[ReauthenticationCoordinator] Should not happen. Missing authentication parameters")
        }
    }
    
    private func start(with authenticatedEndpointRequest: AuthenticatedEndpointRequest) {
        self.userInteractiveAuthenticationService.authenticatedEndpointStatus(for: authenticatedEndpointRequest) { (result) in
            
            switch result {
            case .success(let authenticatedEnpointStatus):
                
                switch authenticatedEnpointStatus {
                case .authenticationNotNeeded:
                    MXLog.debug("[ReauthenticationCoordinator] No need to login again")
                    self.delegate?.reauthenticationCoordinatorDidComplete(self, withAuthenticationParameters: nil)
                case .authenticationNeeded(let authenticationSession):
                    self.start(with: authenticationSession)
                }
            case .failure(let error):
                self.delegate?.reauthenticationCoordinator(self, didFailWithError: error)
            }
        }
    }
    
    private func start(with authenticationSession: MXAuthenticationSession) {
        if self.userInteractiveAuthenticationService.hasPasswordFlow(inFlows: authenticationSession.flows) {
            self.showPasswordAuthentication(with: authenticationSession)
        } else if let authenticationFallbackURL = self.userInteractiveAuthenticationService.firstUncompletedStageAuthenticationFallbackURL(for: authenticationSession) {
            
            self.showFallbackAuthentication(with: authenticationFallbackURL, authenticationSession: authenticationSession)
        } else {
            self.delegate?.reauthenticationCoordinator(self, didFailWithError: UserInteractiveAuthenticationServiceError.flowNotSupported)
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.parameters.presenter.toPresentable()
    }
    
    // MARK: - Private methods

    private func showPasswordAuthentication(with authenticationSession: MXAuthenticationSession) {                
        guard let userId = parameters.session.myUser.userId else {
            return
        }
        
        let passwordViewController = self.uiaViewControllerFactory.createPasswordViewController(title: self.parameters.title, message: self.parameters.message) { [weak self] (password) in
         
            guard let self = self else {
                return
            }
            
            guard let sessionId = authenticationSession.session, let authenticationParameters = self.authenticationParametersBuilder.buildPasswordParameters(sessionId: sessionId, userId: userId, password: password) else {
                self.delegate?.reauthenticationCoordinator(self, didFailWithError: ReauthenticationCoordinatorError.failToBuildPasswordParameters)
                return
            }

            self.delegate?.reauthenticationCoordinatorDidComplete(self, withAuthenticationParameters: authenticationParameters)
            
        } onCancelled: { [weak self] in
            guard let self = self else {
                return
            }
            self.delegate?.reauthenticationCoordinatorDidCancel(self)
        }
        
        self.presentingViewController.present(passwordViewController, animated: true)
    }
    
    private func showFallbackAuthentication(with authenticationURL: URL, authenticationSession: MXAuthenticationSession) {
        
        // NOTE: Prefer use a callback and the same mechanism as SSOAuthentificationSession instead of using custom WKWebView
        let reauthFallbackViewController: ReauthFallBackViewController = ReauthFallBackViewController(url: authenticationURL.absoluteString)
        reauthFallbackViewController.title = self.parameters.title
                
        reauthFallbackViewController.didCancel = { [weak self] in
            guard let self = self else {
                return
            }
            self.delegate?.reauthenticationCoordinatorDidCancel(self)
        }
        
        reauthFallbackViewController.didValidate = { [weak self] in
            guard let self = self else {
                return
            }
            
            guard let sessionId = authenticationSession.session else {
                self.delegate?.reauthenticationCoordinator(self, didFailWithError: ReauthenticationCoordinatorError.failToBuildPasswordParameters)
                return
            }
            
            let authenticationParameters = self.authenticationParametersBuilder.buildOAuthParameters(with: sessionId)
            self.delegate?.reauthenticationCoordinatorDidComplete(self, withAuthenticationParameters: authenticationParameters)
        }
        
        let navigationController = RiotNavigationController(rootViewController: reauthFallbackViewController)
        
        self.presentingViewController.present(navigationController, animated: true)
    }
}
