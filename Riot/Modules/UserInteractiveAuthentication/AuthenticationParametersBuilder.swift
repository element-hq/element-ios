// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
