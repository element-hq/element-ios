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
