// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@objcMembers
/// A service for the SSOAuthenticationPresenter that allows to open an OIDC account management URL.
///
/// Both `callBackURLScheme` and `loginToken` are unneeded for this use case and return `nil`.
final class SSOAccountService: NSObject, SSOAuthenticationServiceProtocol {
    
    // MARK: - Properties
    
    private let accountURL: URL
        
    let callBackURLScheme: String? = nil
    
    // MARK: - Setup
    
    init(accountURL: URL) {
        self.accountURL = accountURL
        super.init()
    }
    
    // MARK: - Public
    
    func authenticationURL(for identityProvider: String?, transactionId: String) -> URL? {
        accountURL
    }
    
    func loginToken(from url: URL) -> String? {
        MXLog.error("The account service shouldn't receive a completion callback.")
        return nil
    }
}
