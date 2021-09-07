// 
// Copyright 2020 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import SafariServices

@objc protocol SSOAuthenticationPresenterDelegate {
    func ssoAuthenticationPresenterDidCancel(_ presenter: SSOAuthenticationPresenter)
    func ssoAuthenticationPresenter(_ presenter: SSOAuthenticationPresenter, authenticationDidFailWithError error: Error)
    func ssoAuthenticationPresenter(_ presenter: SSOAuthenticationPresenter, authenticationSucceededWithToken token: String)
}

enum SSOAuthenticationPresenterError: Error {
    case failToLoadAuthenticationURL
}

/// SSOAuthenticationPresenter enables to present single sign-on authentication
@objcMembers
final class SSOAuthenticationPresenter: NSObject {
    
    // MARK: - Constants
    
    // MARK: - Properties
    
    private let ssoAuthenticationService: SSOAuthenticationService
    
    // MARK: Private
    
    private weak var presentingViewController: UIViewController?
    
    private var authenticationSession: SSOAuthentificationSessionProtocol?
    private weak var safariViewController: SFSafariViewController?
    
    // MARK: Public
    
    weak var delegate: SSOAuthenticationPresenterDelegate?
    
    // MARK: - Setup
    
    init(ssoAuthenticationService: SSOAuthenticationService) {
        self.ssoAuthenticationService = ssoAuthenticationService
        super.init()
    }
    
    // MARK: - Public
    
    func present(forIdentityProviderIdentifier identityProviderIdentifier: String?,
                 with transactionId: String,
                 from presentingViewController: UIViewController,
                 animated: Bool) {
        guard let authenticationURL = self.ssoAuthenticationService.authenticationURL(for: identityProviderIdentifier, transactionId: transactionId) else {
            self.delegate?.ssoAuthenticationPresenter(self, authenticationDidFailWithError: SSOAuthenticationPresenterError.failToLoadAuthenticationURL)
             return
        }
        
        self.presentingViewController = presentingViewController
        
        // NOTE: By using SFAuthenticationSession the consent alert show product name instead of display name. Fallback to SFSafariViewController instead in order to not disturb users with "Riot" wording at the moment.
        // (https://stackoverflow.com/questions/49860338/why-does-sfauthenticationsession-consent-alert-show-xcode-project-name-instead-o)
        if #available(iOS 13.0, *) {
            // SFAuthenticationSession and ASWebAuthenticationSession doesn't work with guided access (rdar://48376122)
            if UIAccessibility.isGuidedAccessEnabled {
                self.presentSafariViewController(with: authenticationURL, animated: animated)
            } else {
                self.startAuthenticationSession(with: authenticationURL)
            }
        } else {
            self.presentSafariViewController(with: authenticationURL, animated: animated)
        }
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        if let safariViewController = self.safariViewController {
            safariViewController.dismiss(animated: animated, completion: completion)
        }
        
        self.authenticationSession?.cancel()
    }
    
    // MARK: - Private
    
    private func presentSafariViewController(with authenticationURL: URL, animated: Bool) {
        guard let presentingViewController = self.presentingViewController else {
            return
        }
        
        let safariViewController = SFSafariViewController(url: authenticationURL)
        safariViewController.dismissButtonStyle = .cancel
        safariViewController.delegate = self
        
        presentingViewController.present(safariViewController, animated: animated, completion: nil)
        self.safariViewController = safariViewController
    }
    
    private func startAuthenticationSession(with authenticationURL: URL) {
        guard let presentingViewController = self.presentingViewController else {
            return
        }
        
        let authenticationSession: SSOAuthentificationSessionProtocol
        
        if #available(iOS 12.0, *) {
            authenticationSession = SSOAuthentificationSession()
        } else {
            authenticationSession = LegacySSOAuthentificationSession()
        }
        
        if #available(iOS 12.0, *) {
            if let presentingWindow = presentingViewController.view.window {
                let contextProvider = SSOAuthenticationSessionContextProvider(window: presentingWindow)
                authenticationSession.setContextProvider(contextProvider)
            }
        }
        
        authenticationSession.authenticate(with: authenticationURL, callbackURLScheme: self.ssoAuthenticationService.callBackURLScheme) { [weak self] (callBackURL, error) in
            guard let self = self else {
                return
            }
            
            if let error = error {
                if case SSOAuthentificationSessionError.userCanceled = error {
                    self.delegate?.ssoAuthenticationPresenterDidCancel(self)
                } else {
                    self.delegate?.ssoAuthenticationPresenter(self, authenticationDidFailWithError: error)
                }
            } else if let successURL = callBackURL {
                if let loginToken = self.ssoAuthenticationService.loginToken(from: successURL) {
                    self.delegate?.ssoAuthenticationPresenter(self, authenticationSucceededWithToken: loginToken)
                } else {
                    MXLog.debug("SSOAuthenticationPresenter: Login token not found")
                    self.delegate?.ssoAuthenticationPresenter(self, authenticationDidFailWithError: SSOAuthenticationServiceError.tokenNotFound)
                }
            }
        }
        
        self.authenticationSession = authenticationSession
    }
}

// MARK: - SFSafariViewControllerDelegate
extension SSOAuthenticationPresenter: SFSafariViewControllerDelegate {
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        self.delegate?.ssoAuthenticationPresenterDidCancel(self)
    }
    
    func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        
        if !didLoadSuccessfully {
            self.delegate?.ssoAuthenticationPresenter(self, authenticationDidFailWithError: SSOAuthenticationPresenterError.failToLoadAuthenticationURL)
        }
    }
}
