// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SafariServices

@objc protocol SSOAuthenticationPresenterDelegate {
    func ssoAuthenticationPresenterDidCancel(_ presenter: SSOAuthenticationPresenter)
    func ssoAuthenticationPresenter(_ presenter: SSOAuthenticationPresenter, authenticationDidFailWithError error: Error)
    func ssoAuthenticationPresenter(_ presenter: SSOAuthenticationPresenter,
                                    authenticationSucceededWithToken token: String,
                                    usingIdentityProvider identityProvider: SSOIdentityProvider?)
}

enum SSOAuthenticationPresenterError: Error {
    case failToLoadAuthenticationURL
}

/// SSOAuthenticationPresenter enables to present single sign-on authentication
@objcMembers
final class SSOAuthenticationPresenter: NSObject {
    
    // MARK: - Constants
    
    // MARK: - Properties
    
    private let ssoAuthenticationService: SSOAuthenticationServiceProtocol
    
    // MARK: Private
    
    private weak var presentingViewController: UIViewController?
    
    private var authenticationSession: SSOAuthentificationSessionProtocol?
    private weak var safariViewController: SFSafariViewController?
    
    // MARK: Public
    
    private(set) var identityProvider: SSOIdentityProvider?
    weak var delegate: SSOAuthenticationPresenterDelegate?
    
    // MARK: - Setup
    
    init(ssoAuthenticationService: SSOAuthenticationServiceProtocol) {
        self.ssoAuthenticationService = ssoAuthenticationService
        super.init()
    }
    
    // MARK: - Public
    
    func present(forIdentityProvider identityProvider: SSOIdentityProvider?,
                 with transactionId: String,
                 from presentingViewController: UIViewController,
                 animated: Bool) {
        guard let authenticationURL = self.ssoAuthenticationService.authenticationURL(for: identityProvider?.id, transactionId: transactionId) else {
            self.delegate?.ssoAuthenticationPresenter(self, authenticationDidFailWithError: SSOAuthenticationPresenterError.failToLoadAuthenticationURL)
             return
        }
        
        self.identityProvider = identityProvider
        self.presentingViewController = presentingViewController
        
        if #unavailable(iOS 15.0), UIAccessibility.isGuidedAccessEnabled {
            // SFAuthenticationSession and ASWebAuthenticationSession doesn't work with guided access (rdar://48376122)
            // Confirmed to be fixed on iOS 15, haven't been able to test on iOS 14.
            presentSafariViewController(with: authenticationURL, animated: animated)
        } else {
            startAuthenticationSession(with: authenticationURL)
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
        
        let authenticationSession = SSOAuthentificationSession()
        
        if let presentingWindow = presentingViewController.view.window {
            let contextProvider = SSOAuthenticationSessionContextProvider(window: presentingWindow)
            authenticationSession.setContextProvider(contextProvider)
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
                    self.delegate?.ssoAuthenticationPresenter(self, authenticationSucceededWithToken: loginToken, usingIdentityProvider: self.identityProvider)
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
