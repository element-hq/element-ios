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
import MatrixSDK

@available(iOS 14.0, *)
struct AuthenticationCoordinatorState {
    // MARK: User choices
    // var serverType: ServerType = .unknown
    // var signMode: SignMode = .unknown
    var resetPasswordEmail: String?
    
    /// Information about the currently selected homeserver.
    var selectedHomeserver: SelectedHomeserver
    
    /// For SSO session recovery
    var deviceId: String?
    
    var knownCustomHomeServersUrls = [String]()
    var isForceLoginFallbackEnabled = false
    
    struct SelectedHomeserver {
        /// The homeserver address as returned by the server.
        var address: String
        /// The homeserver address as input by the user (it can differ to the well-known request).
        var addressFromUser: String?
        
        /// The preferred login mode for the server
        var preferredLoginMode: LoginMode = .unknown
        /// Supported types for the login.
        var loginModeSupportedTypes = [MXLoginFlow]()
    }
    
}
