// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum SSOAuthenticationServiceError: Error {
    case tokenNotFound
    case userCanceled
    case unknown
}

@objc protocol SSOAuthenticationServiceProtocol {
    var callBackURLScheme: String? { get }

    func authenticationURL(for identityProvider: String?, transactionId: String) -> URL?

    func loginToken(from url: URL) -> String?
}

@objcMembers
final class SSOAuthenticationService: NSObject, SSOAuthenticationServiceProtocol {
    
    // MARK: - Constants
    
    // MARK: - Properties
    
    private let homeserverStringURL: String
        
    let callBackURLScheme: String?
    
    // MARK: - Setup
    
    init(homeserverStringURL: String) {
        self.homeserverStringURL = homeserverStringURL
        self.callBackURLScheme = BuildSettings.applicationURLScheme
        super.init()
    }
    
    // MARK: - Public
    
    func authenticationURL(for identityProvider: String?, transactionId: String) -> URL? {
        guard var authenticationComponent = URLComponents(string: self.homeserverStringURL) else {
            return nil
        }
        
        var ssoRedirectPath = SSOURLConstants.Paths.redirect
        
        if let identityProvider = identityProvider, !identityProvider.isEmpty {
            ssoRedirectPath.append("/\(identityProvider)")
        }
        
        authenticationComponent.path = ssoRedirectPath
        
        var queryItems: [URLQueryItem] = []
        
        if let callBackURLScheme = self.buildCallBackURL(with: transactionId) {
            queryItems.append(URLQueryItem(name: SSOURLConstants.Parameters.redirectURL, value: callBackURLScheme))
        }
        
        authenticationComponent.queryItems = queryItems
        
        return authenticationComponent.url
    }
    
    func loginToken(from url: URL) -> String? {
        // If needed convert URL string from HTML entities into correct character representations using UTF8  (like '&amp;' with '&')
        guard let sanitizedStringURL = url.absoluteString.replacingHTMLEntities(),
              let components = URLComponents(string: sanitizedStringURL) else {
            return nil
        }
        return components.vc_getQueryItemValue(for: SSOURLConstants.Parameters.callbackLoginToken)
    }
    
    // MARK: - Private
    
    private func buildCallBackURL(with transactionId: String) -> String? {
        guard let callBackURLScheme = self.callBackURLScheme else {
            return nil
        }
        var urlComponents = URLComponents()
        urlComponents.scheme = callBackURLScheme
        urlComponents.host = CustomSchemeURLConstants.Hosts.connect
        
        // Transaction id is used to indentify the request
        urlComponents.queryItems = [URLQueryItem(name: CustomSchemeURLConstants.Parameters.transactionId, value: transactionId)]
        return urlComponents.string
    }
}
