//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// A `DictionaryEncodable` type that can be used as the parameters of a login request.
protocol LoginParameters: DictionaryEncodable {
    var type: String { get }
}

/// The parameters used for a login request with a token.
struct LoginTokenParameters: LoginParameters {
    let type = kMXLoginFlowTypeToken
    let token: String
}

/// The parameters used for a login request with an ID and password.
struct LoginPasswordParameters: LoginParameters {
    let id: Identifier
    let password: String
    let type: String = kMXLoginFlowTypePassword
    let deviceDisplayName: String?
    let deviceID: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "identifier"
        case password
        case type
        case deviceDisplayName = "initial_device_display_name"
        case deviceID = "device_id"
    }
    
    enum ThreePIDMedium: String { case email, msisdn }
    
    enum Identifier: Encodable {
        case user(String)
        case thirdParty(medium: ThreePIDMedium, address: String)
        case phone(country: String, phone: String)
        
        private enum Constants {
            static let typeKey = "type"
            static let userType = "m.id.user"
            static let thirdPartyType = "m.id.thirdparty"
            static let phoneType = "m.id.phone"
            
            static let userKey = "user"
            
            static let mediumKey = "medium"
            static let addressKey = "address"
            
            static let countryKey = "country"
            static let phoneKey = "phone"
        }
        
        var dictionary: [String: String] {
            switch self {
            case .user(let user):
                return [
                    Constants.typeKey: Constants.userType,
                    Constants.userKey: user
                ]
            case .thirdParty(let medium, let address):
                return [
                    Constants.typeKey: Constants.thirdPartyType,
                    Constants.mediumKey: medium.rawValue,
                    Constants.addressKey: address
                ]
            case .phone(let country, let phone):
                return [
                    Constants.typeKey: Constants.phoneType,
                    Constants.countryKey: country,
                    Constants.phoneKey: phone
                ]
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(dictionary)
        }
    }
}

/// The parameters used when checking that the user has confirmed their email in order to reset their password.
struct CheckResetPasswordParameters: DictionaryEncodable {
    /// Authentication parameters
    let auth: AuthenticationParameters
    /// The new password
    let newPassword: String
    /// The sign out of all devices flag
    let signoutAllDevices: Bool
    
    enum CodingKeys: String, CodingKey {
        case auth
        case newPassword = "new_password"
        case signoutAllDevices = "logout_devices"
    }
    
    init(clientSecret: String, sessionID: String, newPassword: String, signoutAllDevices: Bool) {
        auth = AuthenticationParameters.resetPasswordParameters(clientSecret: clientSecret, sessionID: sessionID)
        self.newPassword = newPassword
        self.signoutAllDevices = signoutAllDevices
    }
}
