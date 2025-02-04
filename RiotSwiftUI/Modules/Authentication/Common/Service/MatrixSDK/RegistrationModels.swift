//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import OrderedCollections

/// The result from a registration screen's coordinator
enum AuthenticationRegistrationStageResult {
    /// The screen completed with the associated registration result.
    case completed(RegistrationResult)
    /// The user would like to cancel the registration.
    case cancel
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
        /// The stage with the type `m.login.email.identity`.
        case email(isMandatory: Bool)
        
        /// The stage with the type `m.login.msisdn`.
        case msisdn(isMandatory: Bool)
        
        /// The stage with the type `m.login.terms`.
        case terms(isMandatory: Bool, terms: MXLoginTerms?)
        
        /// The stage with the type `m.login.recaptcha`.
        case reCaptcha(isMandatory: Bool, siteKey: String)
        
        /// The stage with the type `m.login.dummy`.
        ///
        /// This stage can be mandatory if there is no other stages. In this case the account cannot
        /// be created by just sending a username and a password, the dummy stage has to be completed.
        case dummy(isMandatory: Bool)
        
        /// A stage of an unknown type.
        case other(isMandatory: Bool, type: String, params: [AnyHashable: Any])
        
        /// Whether the stage is mandatory.
        var isMandatory: Bool {
            switch self {
            case .reCaptcha(let isMandatory, _):
                return isMandatory
            case .email(let isMandatory):
                return isMandatory
            case .msisdn(let isMandatory):
                return isMandatory
            case .dummy(let isMandatory):
                return isMandatory
            case .terms(let isMandatory, _):
                return isMandatory
            case .other(let isMandatory, _, _):
                return isMandatory
            }
        }
        
        /// Whether the stage is the dummy stage.
        var isDummy: Bool {
            guard case .dummy = self else { return false }
            return true
        }
    }
    
    /// Determines the next stage to be completed in the flow, following the order Email → Terms → ReCaptcha.
    var nextUncompletedStageOrdered: Stage? {
        if let emailStage = missingStages.first(where: { if case .email = $0 { return true } else { return false } }) {
            return emailStage
        }
        if let termsStage = missingStages.first(where: { if case .terms = $0 { return true } else { return false } }) {
            return termsStage
        }
        if let reCaptchaStage = missingStages.first(where: { if case .reCaptcha = $0 { return true } else { return false } }) {
            return reCaptchaStage
        }
        
        return nextUncompletedStage
    }
    
    /// Determines the next stage to be completed in the flow honouring the server's ordering.
    /// This ordering is slightly broken when the are multiple flows as mandatory stages are
    /// shown first and then optional ones afterwards.
    var nextUncompletedStage: Stage? {
        if let mandatoryStage = missingStages.filter(\.isMandatory).first {
            return mandatoryStage
        }
        return missingStages.first
    }
    
    /// Whether fallback registration should be used due to unsupported stages.
    var needsFallback: Bool {
        missingStages.filter(\.isMandatory).contains { stage in
            if case .other = stage { return true } else { return false }
        }
    }
}

extension MXAuthenticationSession {
    /// The flows from the session mapped as a `FlowResult` value.
    var flowResult: FlowResult {
        let allFlowTypes = OrderedSet(flows.flatMap { $0.stages ?? [] })
        var missingStages = [FlowResult.Stage]()
        var completedStages = [FlowResult.Stage]()
        
        allFlowTypes.forEach { flow in
            let isMandatory = flows.allSatisfy { $0.stages.contains(flow) }
            
            let stage: FlowResult.Stage
            switch flow {
            case kMXLoginFlowTypeRecaptcha:
                let parameters = params[flow] as? [AnyHashable: Any]
                let publicKey = parameters?["public_key"] as? String
                stage = .reCaptcha(isMandatory: isMandatory, siteKey: publicKey ?? "")
            case kMXLoginFlowTypeDummy:
                stage = .dummy(isMandatory: isMandatory)
            case kMXLoginFlowTypeTerms:
                let parameters = params[flow] as? [AnyHashable: Any]
                let terms = MXLoginTerms(fromJSON: parameters)
                stage = .terms(isMandatory: isMandatory, terms: terms)
            case kMXLoginFlowTypeMSISDN:
                stage = .msisdn(isMandatory: isMandatory)
            case kMXLoginFlowTypeEmailIdentity:
                stage = .email(isMandatory: isMandatory)
            default:
                let parameters = params[flow] as? [AnyHashable: Any]
                stage = .other(isMandatory: isMandatory, type: flow, params: parameters ?? [:])
            }
            
            if let completed = completed, completed.contains(flow) {
                completedStages.append(stage)
            } else {
                missingStages.append(stage)
            }
        }
        
        return FlowResult(missingStages: missingStages, completedStages: completedStages)
    }
}

// MARK: - Equatable

extension FlowResult.Stage: Equatable {
    // The [AnyHashable: Any] dictionary breaks automatic conformance, so add manually (but ignore this value).
    static func == (lhs: FlowResult.Stage, rhs: FlowResult.Stage) -> Bool {
        switch (lhs, rhs) {
        case (.email(let lhsMandatory), .email(let rhsMandatory)):
            return lhsMandatory == rhsMandatory
        case (.msisdn(let lhsMandatory), .msisdn(let rhsMandatory)):
            return lhsMandatory == rhsMandatory
        case (.terms(let lhsMandatory, let lhsTerms), .terms(let rhsMandatory, let rhsTerms)):
            // TODO: Add comprehensive Equatable conformance on MXLoginTerms
            return lhsMandatory == rhsMandatory && lhsTerms?.policies == rhsTerms?.policies
        case (.reCaptcha(let lhsMandatory, let lhsSiteKey), .reCaptcha(let rhsMandatory, let rhsSiteKey)):
            return lhsMandatory == rhsMandatory && lhsSiteKey == rhsSiteKey
        case (.dummy(let lhsMandatory), .dummy(let rhsMandatory)):
            return lhsMandatory == rhsMandatory
        case (.other(let lhsMandatory, let lhsType, _), .other(let rhsMandatory, let rhsType, _)):
            return lhsMandatory == rhsMandatory && lhsType == rhsType
        default:
            return false
        }
    }
}
