// 
// Copyright 2021 New Vector Ltd
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
