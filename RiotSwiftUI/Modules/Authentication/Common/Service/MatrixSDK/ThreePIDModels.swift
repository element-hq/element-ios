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

enum RegisterThreePID {
    case email(String)
    case msisdn(msisdn: String, countryCode: String)
}

struct ThreePIDCredentials: Codable, Equatable {
    var clientSecret: String?
    
    var identityServer: String?
    
    var sessionID: String?
    
    enum CodingKeys: String, CodingKey {
        case clientSecret = "client_secret"
        case identityServer = "id_server"
        case sessionID = "sid"
    }
}

struct ThreePIDData {
    let threePID: RegisterThreePID
    let registrationResponse: RegistrationThreePIDTokenResponse
    let registrationParameters: RegistrationParameters
}

// TODO: This could potentially become an MXJSONModel?
struct RegistrationThreePIDTokenResponse {
    /// Required. The session ID. Session IDs are opaque strings that must consist entirely of the characters [0-9a-zA-Z.=_-].
    /// Their length must not exceed 255 characters and they must not be empty.
    let sessionID: String
    
    /// An optional field containing a URL where the client must submit the validation token to, with identical parameters to the Identity
    /// Service API's POST /validate/email/submitToken endpoint. The homeserver must send this token to the user (if applicable),
    /// who should then be prompted to provide it to the client.
    ///
    /// If this field is not present, the client can assume that verification will happen without the client's involvement provided
    /// the homeserver advertises this specification version in the /versions response (ie: r0.5.0).
    var submitURL: String?
    
    // MARK: - Additional data that may be needed
    
    var msisdn: String?
    var formattedMSISDN: String?
    var success: Bool?
    
    enum CodingKeys: String, CodingKey {
        case sessionID = "sid"
        case submitURL = "submit_url"
        case msisdn
        case formattedMSISDN = "intl_fmt"
        case success
    }
}

struct ThreePIDValidationCodeBody: Codable {
    let clientSecret: String
    
    let sessionID: String
    
    let code: String
    
    enum CodingKeys: String, CodingKey {
        case clientSecret = "client_secret"
        case sessionID = "sid"
        case code = "token"
    }
    
    func jsonData() throws -> Data {
        try JSONEncoder().encode(self)
    }
}
