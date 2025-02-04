// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import AnalyticsEvents

extension AuthenticationType {
    var analyticsType: AnalyticsEvent.Signup.AuthenticationType {
        switch self {
        case .password:
            return .Password
        case .sso(let provider):
            guard let brandString = provider.brand else { return .SSO }
            let brand = MXLoginSSOIdentityProviderBrand(brandString)
            switch brand {
            case .apple:
                return .Apple
            case .facebook:
                return .Facebook
            case .github:
                return .GitHub
            case .gitlab:
                return .GitLab
            case .google:
                return .Google
            default:
                return .SSO
            }
        case .other:
            return .Other
        }
    }
}
