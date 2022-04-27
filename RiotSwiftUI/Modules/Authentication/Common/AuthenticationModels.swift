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

/// A value that represents the type of authentication flow being used.
enum AuthenticationFlow {
    case login
    case registration
}

/// Errors that can be thrown from `AuthenticationService`.
enum AuthenticationError: String, Error {
    /// A failure to convert a struct into a dictionary.
    case dictionaryError
    case invalidHomeserver
    case loginFlowNotCalled
    case missingRegistrationWizard
    case missingMXRestClient
}

/// Errors that can be thrown from `RegistrationWizard`
enum RegistrationError: String, Error {
    case createAccountNotCalled
    case missingThreePIDData
    case missingThreePIDURL
    case threePIDValidationFailure
    case threePIDClientFailure
}

/// Errors that can be thrown from `LoginWizard`
enum LoginError: String, Error {
    case unimplemented
}

/// Represents an SSO Identity Provider as provided in a login flow.
struct SSOIdentityProvider: Identifiable {
    /// The identifier field (id field in JSON) is the Identity Provider identifier used for the SSO Web page redirection `/login/sso/redirect/{idp_id}`.
    let id: String
    /// The name field is a human readable string intended to be printed by the client.
    let name: String
    /// The brand field is optional. It allows the client to style the login button to suit a particular brand.
    let brand: String?
    /// The icon field is an optional field that points to an icon representing the identity provider. If present then it must be an HTTPS URL to an image resource.
    let iconURL: String?
}
