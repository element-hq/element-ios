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

/// A value that represents an authentication flow as either login or register.
enum AuthenticationFlow {
    case login
    case register
}

/// A value that represents the type of authentication used.
enum AuthenticationType {
    /// A username and password.
    case password
    /// SSO with the associated provider
    case sso(SSOIdentityProvider)
    /// Some other method such as the fall back page.
    case other
}

/// Errors that can be thrown from `AuthenticationService`.
enum AuthenticationError: String, LocalizedError {
    case invalidHomeserver
    case loginFlowNotCalled
    case missingMXRestClient
    
    var errorDescription: String? {
        switch self {
        case .invalidHomeserver:
            return VectorL10n.authenticationServerSelectionGenericError
        default:
            return VectorL10n.errorCommonMessage
        }
    }
}

/// Errors that can be thrown from `RegistrationWizard`
enum RegistrationError: String, LocalizedError {
    case registrationDisabled
    case createAccountNotCalled
    case missingThreePIDData
    case missingThreePIDURL
    case threePIDValidationFailure
    case threePIDClientFailure
    case waitingForThreePIDValidation
    case invalidPhoneNumber
    
    var errorDescription: String? {
        switch self {
        case .registrationDisabled:
            return VectorL10n.loginErrorRegistrationIsNotSupported
        case .threePIDValidationFailure, .threePIDClientFailure:
            return VectorL10n.authMsisdnValidationError
        case .invalidPhoneNumber:
            return VectorL10n.authenticationVerifyMsisdnInvalidPhoneNumber
        default:
            return VectorL10n.errorCommonMessage
        }
    }
}

/// Errors that can be thrown from `LoginWizard`
enum LoginError: String, Error {
    case resetPasswordNotStarted
}

@objcMembers 
class HomeserverAddress: NSObject {
    /// Sanitizes a user entered homeserver address with the following rules
    /// - Trim any whitespace.
    /// - Lowercase the address.
    /// - Ensure the address contains a scheme, otherwise make it `https`.
    /// - Remove any trailing slashes.
    static func sanitized(_ address: String) -> String {
        var address = address.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        if !address.contains("://") {
            address = "https://\(address)"
        }
        
        address = address.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        return address
    }
}

/// Represents an SSO Identity Provider as provided in a login flow.
@objc class SSOIdentityProvider: NSObject, Identifiable {
    /// The id field is the Identity Provider identifier used for the SSO Web page redirection `/login/sso/redirect/{idp_id}`.
    let id: String
    /// The name field is a human readable string intended to be printed by the client.
    let name: String
    /// The brand field is optional. It allows the client to style the login button to suit a particular brand.
    let brand: String?
    /// The icon field is an optional field that points to an icon representing the identity provider. If present then it must be an HTTPS URL to an image resource.
    let iconURL: String?
    
    init(id: String, name: String, brand: String?, iconURL: String?) {
        self.id = id
        self.name = name
        self.brand = brand
        self.iconURL = iconURL
    }
}
