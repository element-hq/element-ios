// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum SSOURLConstants {
    
    enum Parameters {
        static let callbackLoginToken = "loginToken"
        static let redirectURL = "redirectUrl"
    }
    
    enum Paths {
        static let redirect = "/_matrix/client/r0/login/sso/redirect"
    }
}
