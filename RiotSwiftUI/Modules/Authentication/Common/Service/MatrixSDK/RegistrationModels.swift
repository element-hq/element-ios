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

/// The parameters used for registration requests.
struct RegistrationParameters: Codable {
    /// Authentication parameters
    var auth: AuthenticationParameters?
    
    /// The account username
    var username: String?
    
    /// The account password
    var password: String?
    
    /// Device name
    var initialDeviceDisplayName: String?
    
    /// Temporary flag to notify the server that we support MSISDN flow. Used to prevent old app
    /// versions to end up in fallback because the HS returns the MSISDN flow which they don't support
    var xShowMSISDN: Bool?
    
    enum CodingKeys: String, CodingKey {
        case auth
        case username
        case password
        case initialDeviceDisplayName = "initial_device_display_name"
        case xShowMSISDN = "x_show_msisdn"
    }
    
    /// The parameters as a JSON dictionary for use in MXRestClient.
    func dictionary() throws -> [String: Any] {
        let jsonData = try JSONEncoder().encode(self)
        let object = try JSONSerialization.jsonObject(with: jsonData)
        guard let dictionary = object as? [String: Any] else {
            MXLog.error("[RegistrationParameters] dictionary: Unexpected type decoded \(type(of: object)). Expected a Dictionary.")
            throw AuthenticationError.dictionaryError
        }
        
        return dictionary
    }
}

/// The data passed to the `auth` parameter in authentication requests.
struct AuthenticationParameters: Codable {
    /// The type of authentication taking place. The identifier from `MXLoginFlowType`.
    let type: String
    
    /// Note: session can be null for reset password request
    var session: String?
    
    /// parameter for "m.login.recaptcha" type
    var captchaResponse: String?
    
    /// parameter for "m.login.email.identity" type
    var threePIDCredentials: ThreePIDCredentials?
    
    enum CodingKeys: String, CodingKey {
        case type
        case session
        case captchaResponse = "response"
        case threePIDCredentials = "threepid_creds"
    }
    
    /// Creates the authentication parameters for a captcha step.
    static func captchaParameters(session: String, captchaResponse: String) -> AuthenticationParameters {
        AuthenticationParameters(type: kMXLoginFlowTypeRecaptcha, session: session, captchaResponse: captchaResponse)
    }
    
    /// Creates the authentication parameters for a third party ID step using an email address.
    static func emailIdentityParameters(session: String, threePIDCredentials: ThreePIDCredentials) -> AuthenticationParameters {
        AuthenticationParameters(type: kMXLoginFlowTypeEmailIdentity, session: session, threePIDCredentials: threePIDCredentials)
    }
    
    // Note that there is a bug in Synapse (needs investigation), but if we pass .msisdn,
    // the homeserver answer with the login flow with MatrixError fields and not with a simple MatrixError 401.
    /// Creates the authentication parameters for a third party ID step using a phone number.
    static func msisdnIdentityParameters(session: String, threePIDCredentials: ThreePIDCredentials) -> AuthenticationParameters {
        AuthenticationParameters(type: kMXLoginFlowTypeMSISDN, session: session, threePIDCredentials: threePIDCredentials)
    }
    
    /// Creates the authentication parameters for a password reset step.
    static func resetPasswordParameters(clientSecret: String, sessionID: String) -> AuthenticationParameters {
        AuthenticationParameters(type: kMXLoginFlowTypeEmailIdentity,
                                 session: nil,
                                 threePIDCredentials: ThreePIDCredentials(clientSecret: clientSecret, sessionID: sessionID))
    }
}

/// The result from a response of a registration flow step.
enum RegistrationResult {
    /// Registration has completed, creating an `MXSession` for the account.
    case success(MXSession)
    /// The request was successful but there are pending steps to complete.
    case flowResponse(FlowResult)
}

/// The state of an authentication flow after a step has been completed.
struct FlowResult {
    /// The stages in the flow that are yet to be completed.
    let missingStages: [Stage]
    /// The stages in the flow that have been completed.
    let completedStages: [Stage]
    
    /// A stage in the authentication flow.
    enum Stage {
        /// The stage with the type `m.login.recaptcha`.
        case reCaptcha(mandatory: Bool, publicKey: String)
        
        /// The stage with the type `m.login.email.identity`.
        case email(mandatory: Bool)
        
        /// The stage with the type `m.login.msisdn`.
        case msisdn(mandatory: Bool)
        
        /// The stage with the type `m.login.dummy`.
        ///
        /// This stage can be mandatory if there is no other stages. In this case the account cannot
        /// be created by just sending a username and a password, the dummy stage has to be completed.
        case dummy(mandatory: Bool)
        
        /// The stage with the type `m.login.terms`.
        case terms(mandatory: Bool, policies: [String: String])
        
        /// A stage of an unknown type.
        case other(mandatory: Bool, type: String, params: [AnyHashable: Any])
        
        /// Whether the stage is a dummy stage that is also mandatory.
        var isDummyAndMandatory: Bool {
            guard case let .dummy(isMandatory) = self else { return false }
            return isMandatory
        }
    }
}

extension MXAuthenticationSession {
    /// The flows from the session mapped as a `FlowResult` value.
    var flowResult: FlowResult {
        let allFlowTypes = Set(flows.flatMap { $0.stages ?? [] })
        var missingStages = [FlowResult.Stage]()
        var completedStages = [FlowResult.Stage]()
        
        allFlowTypes.forEach { flow in
            let isMandatory = flows.allSatisfy { $0.stages.contains(flow) }
            
            let stage: FlowResult.Stage
            switch flow {
            case kMXLoginFlowTypeRecaptcha:
                let parameters = params[flow] as? [AnyHashable: Any]
                let publicKey = parameters?["public_key"] as? String
                stage = .reCaptcha(mandatory: isMandatory, publicKey: publicKey ?? "")
            case kMXLoginFlowTypeDummy:
                stage = .dummy(mandatory: isMandatory)
            case kMXLoginFlowTypeTerms:
                let parameters = params[flow] as? [String: String]
                stage = .terms(mandatory: isMandatory, policies: parameters ?? [:])
            case kMXLoginFlowTypeMSISDN:
                stage = .msisdn(mandatory: isMandatory)
            case kMXLoginFlowTypeEmailIdentity:
                stage = .email(mandatory: isMandatory)
            default:
                let parameters = params[flow] as? [AnyHashable: Any]
                stage = .other(mandatory: isMandatory, type: flow, params: parameters ?? [:])
            }
            
            if let completed = completed, completed.contains(flow) {
                completedStages.append(stage)
            } else {
                missingStages.append(stage)
            }
        }
        
        return FlowResult(missingStages: missingStages, completedStages: completedStages)
    }
    
    /// Determines the next stage to be completed in the flow.
    func nextUncompletedStage(flowIndex: Int = 0) -> String? {
        guard flows.count < flowIndex else { return nil }
        return flows[flowIndex].stages.first {
            guard let completed = completed else { return false }
            return !completed.contains($0)
        }
    }
}
