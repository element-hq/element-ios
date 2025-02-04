//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
    case delegatedOIDCRequiresReplacementApp
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
        case .delegatedOIDCRequiresReplacementApp:
            return VectorL10n.sunsetDelegatedOidcRegistrationNotSupportedGenericError
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
        guard !address.isEmpty else {
            // prevent prefixing an empty string with "https:"
            return address
        }
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
