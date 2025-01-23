//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import Element

class RegistrationTests: XCTestCase {
    /// Makes an authentication session that mimics the matrix.org flow.
    func makeSession() -> MXAuthenticationSession {
        let flow = MXLoginFlow()
        flow.stages = [kMXLoginFlowTypeRecaptcha, kMXLoginFlowTypeTerms, kMXLoginFlowTypeEmailIdentity]
        
        let session = MXAuthenticationSession()
        session.flows = [flow]
        session.params = [:]
        return session
    }
    
    /// Makes an authentication session that has two flows.
    func makeSessionWithTwoFlows() -> MXAuthenticationSession {
        let flow1 = MXLoginFlow()
        flow1.stages = [kMXLoginFlowTypeMSISDN, kMXLoginFlowTypeTerms, kMXLoginFlowTypeRecaptcha]
        
        let flow2 = MXLoginFlow()
        flow2.stages = [kMXLoginFlowTypeEmailIdentity, kMXLoginFlowTypeTerms, kMXLoginFlowTypeRecaptcha]
        
        let session = MXAuthenticationSession()
        session.flows = [flow1, flow2]
        session.params = [:]
        return session
    }
    
    func testRegistrationResultForNewSession() {
        // Given a fresh session.
        let session = makeSession()
        
        // Then the result should have no completed stages.
        let flowResult = session.flowResult
        XCTAssertEqual(flowResult.completedStages.count, 0,
                       "There should be no completed stages for a new session.")
        XCTAssertEqual(flowResult.missingStages.count, 3,
                       "The result should have 3 missing stages.")
        XCTAssertEqual(flowResult.nextUncompletedStage, .reCaptcha(isMandatory: true, siteKey: ""),
                       "The first stage should match the order in the session.")
        XCTAssertEqual(flowResult.nextUncompletedStageOrdered, .email(isMandatory: true),
                       "The first stage when ordered should be Email for a new session.")
        XCTAssertFalse(flowResult.needsFallback,
                       "Fallback shouldn't be needed when the stages are all supported.")
    }
    
    func testRegistrationResultAfterEmail() {
        // Given a fresh session.
        let session = makeSession()
        
        // When completing the email stage.
        session.completed = [kMXLoginFlowTypeEmailIdentity]
        
        // Then the result should reflect the first stage has been completed.
        let flowResult = session.flowResult
        XCTAssertEqual(flowResult.completedStages.count, 1,
                       "The result should have 1 completed stage.")
        XCTAssertEqual(flowResult.missingStages.count, 2,
                       "The result should have 2 missing stages.")
        XCTAssertEqual(flowResult.nextUncompletedStage, .reCaptcha(isMandatory: true, siteKey: ""),
                       "The next stage should be the ReCaptcha stage.")
        XCTAssertEqual(flowResult.nextUncompletedStageOrdered, .terms(isMandatory: true, terms: MXLoginTerms(fromJSON: [:])),
                       "The next stage when ordered should be the Terms stage.")
    }
    
    func testRegistrationResultAfterEmailAndTerms() {
        // Given a fresh session.
        let session = makeSession()
        
        // When completing the email and terms stages.
        session.completed = [kMXLoginFlowTypeEmailIdentity, kMXLoginFlowTypeTerms]
        
        // Then the result should reflect the first 2 stages have been completed.
        let flowResult = session.flowResult
        XCTAssertEqual(flowResult.completedStages.count, 2,
                       "The result should have 2 completed stages.")
        XCTAssertEqual(flowResult.missingStages.count, 1,
                       "The result should have 1 missing stage.")
        XCTAssertEqual(flowResult.nextUncompletedStage, .reCaptcha(isMandatory: true, siteKey: ""),
                       "The next stage should be the ReCaptcha stage.")
        XCTAssertEqual(flowResult.nextUncompletedStageOrdered, .reCaptcha(isMandatory: true, siteKey: ""),
                       "The next stage when ordered should be the ReCaptcha stage.")
    }
    
    func testRegistrationResultAfterAllStages() {
        // Given a fresh session.
        let session = makeSession()
        
        // When completing all of the stages.
        session.completed = [kMXLoginFlowTypeEmailIdentity, kMXLoginFlowTypeTerms, kMXLoginFlowTypeRecaptcha]
        
        // Then the result shouldn't have any missing stages.
        let flowResult = session.flowResult
        XCTAssertEqual(flowResult.completedStages.count, 3,
                       "The result should have all completed stages.")
        XCTAssertEqual(flowResult.missingStages.count, 0,
                       "The result should have no missing stages.")
        XCTAssertNil(flowResult.nextUncompletedStage,
                     "There shouldn't be any more stages to complete.")
        XCTAssertNil(flowResult.nextUncompletedStageOrdered,
                     "There shouldn't be any more stages to complete.")
    }
    
    func testRegistrationResultCustomStage() {
        // Given a session that contains a single flow with a custom stage.
        let session = makeSession()
        session.flows.first?.stages.append("test.flow")
        
        // Then the result should indicate that fallback authentication should be used.
        let flowResult = session.flowResult
        XCTAssertTrue(flowResult.needsFallback, "Fallback should be required when a custom stage is present.")
    }
    
    func testRegistrationResultTwoFlows() {
        // Given a session with two flows.
        let session = makeSessionWithTwoFlows()
        
        // Then the result should know the mandatory/optional stages and start with the mandatory stages unless ordered
        let flowResult = session.flowResult
        XCTAssertFalse(flowResult.needsFallback,
                       "Fallback shouldn't be needed when the stages are all supported.")
        XCTAssertEqual(flowResult.nextUncompletedStage, .terms(isMandatory: true, terms: MXLoginTerms(fromJSON: [:])),
                       "The first stage should be the Terms stage.")
        XCTAssertEqual(flowResult.nextUncompletedStageOrdered, .email(isMandatory: false),
                       "The first stage when ordered should be the Email stage.")
        
        flowResult.missingStages.forEach { stage in
            switch stage {
            case .email(let isMandatory):
                XCTAssertFalse(isMandatory, "The Email stage should be optional.")
            case .msisdn(let isMandatory):
                XCTAssertFalse(isMandatory, "The MSISDN stage should be optional.")
            case .terms(let isMandatory, _):
                XCTAssertTrue(isMandatory, "The Terms stage should be mandatory.")
            case .reCaptcha(let isMandatory, _):
                XCTAssertTrue(isMandatory, "The ReCaptcha stage should be mandatory.")
            default:
                XCTFail("There shouldn't be any other types of stage in the result.")
            }
        }
    }
    
    func testRegistrationResultTwoFlowsAfterMandatoryStages() {
        // Given a session with two flows.
        let session = makeSessionWithTwoFlows()
        
        // When completing the terms and recaptcha stages.
        session.completed = [kMXLoginFlowTypeTerms, kMXLoginFlowTypeRecaptcha]
        
        // Then the result should have the optional stages remaining.
        let flowResult = session.flowResult
        XCTAssertEqual(flowResult.completedStages.count, 2,
                       "The result should have 2 completed stages.")
        XCTAssertEqual(flowResult.missingStages.count, 2,
                       "The result should have 2 missing stage.")
        XCTAssertEqual(flowResult.nextUncompletedStage, .msisdn(isMandatory: false),
                       "The next stage should be the MSISDN stage.")
        XCTAssertEqual(flowResult.nextUncompletedStageOrdered, .email(isMandatory: false),
                       "The next stage when ordered should be the Email stage.")
    }
    
    func testRegistrationResultTwoFlowsCustomStage() {
        // Given a session with a custom stage in a second flow.
        let session = makeSession()
        let flow = MXLoginFlow()
        flow.stages = ["test.flow"]
        session.flows.append(flow)
        
        // Then the session shouldn't need fallback.
        let flowResult = session.flowResult
        XCTAssertFalse(flowResult.needsFallback, "Fallback shouldn't be required when a custom stage is optional.")
    }
}
