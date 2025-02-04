// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// ReauthenticationCoordinator input parameters
@objcMembers
class ReauthenticationCoordinatorParameters: NSObject {
    
    // MARK: - Properties
    
    /// The Matrix session
    let session: MXSession
    
    /// The presenter used to show authentication screen(s).
    /// Note: Use UIViewController instead of Presentable for ObjC compatibility.
    let presenter: UIViewController
    
    /// The title to use in the authentication screen if present.
    let title: String?
    
    /// The message to use in the authentication screen if present.
    let message: String?
    
    /// The authenticated API endpoint request.
    let authenticatedEndpointRequest: AuthenticatedEndpointRequest?
    
    /// The MXAuthentication session retrieved from a request error.
    /// Note: If the property is not nil `authenticatedEndpointRequest` will not be taken into account.
    let authenticationSession: MXAuthenticationSession?
    
    // MARK: - Setup
    
    convenience init(session: MXSession,
         presenter: UIViewController,
         title: String?,
         message: String?,
         authenticatedEndpointRequest: AuthenticatedEndpointRequest) {
        self.init(session: session,
                  presenter: presenter,
                  title: title,
                  message: message,
                  authenticatedEndpointRequest: authenticatedEndpointRequest,
                  authenticationSession: nil)
    }
    
    convenience init(session: MXSession,
         presenter: UIViewController,
         title: String?,
         message: String?,
         authenticationSession: MXAuthenticationSession) {
        self.init(session: session, presenter: presenter, title: title, message: message, authenticatedEndpointRequest: nil, authenticationSession: authenticationSession)
    }
    
    private init(session: MXSession,
         presenter: UIViewController,
         title: String?,
         message: String?,
         authenticatedEndpointRequest: AuthenticatedEndpointRequest?,
         authenticationSession: MXAuthenticationSession?) {
        self.session = session
        self.presenter = presenter
        self.title = title
        self.message = message
        self.authenticatedEndpointRequest = authenticatedEndpointRequest
        self.authenticationSession = authenticationSession
    }
}
