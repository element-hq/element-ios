// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// SocialLoginButton view data
struct SocialLoginButtonViewData {
    
    /// Identity provider identifier
    let identityProvider: SSOIdentityProvider
    
    /// Button title
    let title: String
    
    /// Default button style
    let defaultStyle: SocialLoginButtonStyle
    
    /// Button style per theme identifier
    let themeStyles: [String: SocialLoginButtonStyle]
}
