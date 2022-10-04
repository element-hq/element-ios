//
// Copyright 2022 New Vector Ltd
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

/// Information about a homeserver that is ready for display in the authentication flow.
struct AuthenticationHomeserverViewData: Equatable {
    /// The homeserver string to be shown to the user.
    let address: String
    /// Whether or not to display the username and password text fields during login.
    let showLoginForm: Bool
    /// Whether or not to display the username and password text fields during registration.
    let showRegistrationForm: Bool
    /// Whether or not to display the QR login button during login.
    let showQRLogin: Bool
    /// The supported SSO login options.
    let ssoIdentityProviders: [SSOIdentityProvider]
}

// MARK: - Mocks

extension AuthenticationHomeserverViewData {
    /// A mock homeserver that is configured just like matrix.org.
    static var mockMatrixDotOrg: AuthenticationHomeserverViewData {
        AuthenticationHomeserverViewData(address: "matrix.org",
                                         showLoginForm: true,
                                         showRegistrationForm: true,
                                         showQRLogin: false,
                                         ssoIdentityProviders: [
                                             SSOIdentityProvider(id: "1", name: "Apple", brand: "apple", iconURL: nil),
                                             SSOIdentityProvider(id: "2", name: "Facebook", brand: "facebook", iconURL: nil),
                                             SSOIdentityProvider(id: "3", name: "GitHub", brand: "github", iconURL: nil),
                                             SSOIdentityProvider(id: "4", name: "GitLab", brand: "gitlab", iconURL: nil),
                                             SSOIdentityProvider(id: "5", name: "Google", brand: "google", iconURL: nil)
                                         ])
    }
    
    /// A mock homeserver that supports login and registration via a password but has no SSO providers.
    static var mockBasicServer: AuthenticationHomeserverViewData {
        AuthenticationHomeserverViewData(address: "example.com",
                                         showLoginForm: true,
                                         showRegistrationForm: true,
                                         showQRLogin: false,
                                         ssoIdentityProviders: [])
    }
    
    /// A mock homeserver that supports only supports authentication via a single SSO provider.
    static var mockEnterpriseSSO: AuthenticationHomeserverViewData {
        AuthenticationHomeserverViewData(address: "company.com",
                                         showLoginForm: false,
                                         showRegistrationForm: false,
                                         showQRLogin: false,
                                         ssoIdentityProviders: [SSOIdentityProvider(id: "test", name: "SAML", brand: nil, iconURL: nil)])
    }

    /// A mock homeserver that supports only supports authentication via fallback.
    static var mockFallback: AuthenticationHomeserverViewData {
        AuthenticationHomeserverViewData(address: "company.com",
                                         showLoginForm: false,
                                         showRegistrationForm: false,
                                         showQRLogin: false,
                                         ssoIdentityProviders: [])
    }
}
