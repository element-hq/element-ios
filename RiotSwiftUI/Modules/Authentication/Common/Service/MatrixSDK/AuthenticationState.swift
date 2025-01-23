//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixSDK

struct AuthenticationState {
    // var serverType: ServerType = .unknown
    var flow: AuthenticationFlow
    
    /// Information about the currently selected homeserver.
    var homeserver: Homeserver
    /// Currently selected identity server
    var identityServer: String?
    var isForceLoginFallbackEnabled = false
    
    init(flow: AuthenticationFlow, homeserverAddress: String, identityServer: String? = nil) {
        self.flow = flow
        homeserver = Homeserver(address: homeserverAddress)
        self.identityServer = identityServer
    }
    
    init(flow: AuthenticationFlow, homeserver: Homeserver, identityServer: String? = nil) {
        self.flow = flow
        self.homeserver = homeserver
        self.identityServer = identityServer
    }
    
    struct Homeserver {
        /// The homeserver address as returned by the server.
        var address: String
        /// The homeserver address as input by the user (it can differ to the well-known request).
        var addressFromUser: String?
        /// The homeserver's address formatted to be displayed to the user in labels, text fields etc.
        var displayableAddress: String {
            let address = addressFromUser ?? address
            return address.replacingOccurrences(of: "https://", with: "") // Only remove https. Leave http to indicate the server doesn't use SSL.
        }
        
        /// The preferred login mode for the server
        var preferredLoginMode: LoginMode = .unknown

        /// Flag indicating whether the homeserver supports logging in via a QR code.
        var supportsQRLogin = false
        
        /// The response returned when querying the homeserver for registration flows.
        var registrationFlow: RegistrationResult?
        
        /// Whether or not the homeserver is for matrix.org.
        var isMatrixDotOrg: Bool {
            guard let url = URL(string: address) else { return false }
            return url.host == "matrix.org" || url.host == "matrix-client.matrix.org"
        }
        
        /// The homeserver mapped into view data that is ready for display.
        var viewData: AuthenticationHomeserverViewData {
            AuthenticationHomeserverViewData(address: displayableAddress,
                                             showLoginForm: preferredLoginMode.supportsPasswordFlow,
                                             showRegistrationForm: registrationFlow != nil && !needsRegistrationFallback,
                                             showQRLogin: supportsQRLogin,
                                             ssoIdentityProviders: preferredLoginMode.ssoIdentityProviders ?? [])
        }

        /// Needs authentication fallback for login
        var needsLoginFallback: Bool {
            preferredLoginMode.isUnsupported
        }

        /// Needs authentication fallback for registration
        var needsRegistrationFallback: Bool {
            guard let flow = registrationFlow else {
                return false
            }
            switch flow {
            case .flowResponse(let result):
                return result.needsFallback
            default:
                return false
            }
        }
    }
}
