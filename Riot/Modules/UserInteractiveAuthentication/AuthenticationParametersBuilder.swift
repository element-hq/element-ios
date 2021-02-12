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

/// Build authentication parameters depending on login type
final class AuthenticationParametersBuilder {
    
    func buildPasswordParameters(sessionId: String,
                                 userId: String,
                                 password: String) -> [String: Any]? {
        return [
            "type": MXLoginFlowType.password.identifier,
            "session": sessionId,
            "user": userId,
            "password": password
        ]
    }
    
    func buildTokenParameters(with loginToken: String) -> [String: Any] {
        return [
            "type": MXLoginFlowType.token.identifier,
            "token": loginToken
        ]
    }
    
    func buildOAuthParameters(with sessionId: String) -> [String: Any] {
        return [
            "session": sessionId
        ]
    }
}
