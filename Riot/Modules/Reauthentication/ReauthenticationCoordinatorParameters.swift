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
    
    /// The Matrix session
    let session: MXSession
    
    /// The presenter used to show authentication screen(s)
    let presenter: Presentable
    
    /// The title to use in the authentication screen if present.
    let title: String?
    
    /// The message to use in the authentication screen if present.
    let message: String?
    
    /// The authenticated API endpoint parameters
    let authenticationSessionParameters: AuthenticationSessionParameters
    
    init(session: MXSession,
         presenter: Presentable,
         title: String?,
         message: String?,
         authenticationSessionParameters: AuthenticationSessionParameters) {
        self.session = session
        self.presenter = presenter
        self.title = title
        self.message = message
        self.authenticationSessionParameters = authenticationSessionParameters
    }
}
