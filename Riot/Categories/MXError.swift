// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import MatrixSDK

extension MXError {
    /// Returns custom localized message from errcode parameter of MXError.
    func authenticationErrorMessage() -> String {
        let message: String
        switch self.errcode {
        case kMXErrCodeStringForbidden:
            message = VectorL10n.loginErrorForbidden
        case kMXErrCodeStringUnknownToken:
            message = VectorL10n.loginErrorUnknownToken
        case kMXErrCodeStringBadJSON:
            message = VectorL10n.loginErrorBadJson
        case kMXErrCodeStringNotJSON:
            message = VectorL10n.loginErrorBadJson
        case kMXErrCodeStringLimitExceeded:
            message = VectorL10n.loginErrorLimitExceeded
        case kMXErrCodeStringUserInUse:
            message = VectorL10n.loginErrorUserInUse
        case kMXErrCodeStringLoginEmailURLNotYet:
            message = VectorL10n.loginErrorLoginEmailNotYet
        case kMXErrCodeStringThreePIDInUse:
            message = VectorL10n.authEmailInUse
        case kMXErrCodeStringPasswordTooShort:
            message = VectorL10n.passwordPolicyTooShortPwdError
        case kMXErrCodeStringPasswordNoDigit:
            message = VectorL10n.passwordPolicyWeakPwdError
        case kMXErrCodeStringPasswordNoLowercase:
            message = VectorL10n.passwordPolicyWeakPwdError
        case kMXErrCodeStringPasswordNoUppercase:
            message = VectorL10n.passwordPolicyWeakPwdError
        case kMXErrCodeStringPasswordNoSymbol:
            message = VectorL10n.passwordPolicyWeakPwdError
        case kMXErrCodeStringWeakPassword:
            message = VectorL10n.passwordPolicyWeakPwdError
        case kMXErrCodeStringPasswordInDictionary:
            message = VectorL10n.passwordPolicyPwdInDictError
        default:
            message = self.error
        }
        
        return message
    }
}
