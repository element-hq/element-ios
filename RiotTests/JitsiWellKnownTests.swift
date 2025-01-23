// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import Element

class JitsiWellKnownTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: - Tests
    
    func testJitsiWellKnownParsingKnownValue() {

        let wellKnownDictionary: [String: Any] = [
            "auth": "openidtoken-jwt"
        ]
        
        let serializationService = SerializationService()

        do {
            let jitsiWellKnown: JitsiWellKnown = try serializationService.deserialize(wellKnownDictionary)

            let jistiAuthenticationType = jitsiWellKnown.authenticationType

            XCTAssertNotNil(jistiAuthenticationType)

            XCTAssertEqual(jistiAuthenticationType, .openIDTokenJWT)
        } catch {
            XCTFail("Fail with error: \(error)")
        }
    }
    
    func testJitsiWellKnownParsingUnknownValue() {

        let expectedAuthenticationTypeString = "other-authentication"
        
        let wellKnownDictionary: [String: Any] = [
            "auth": expectedAuthenticationTypeString
        ]
        
        let serializationService = SerializationService()

        do {
            let jitsiWellKnown: JitsiWellKnown = try serializationService.deserialize(wellKnownDictionary)

            let jistiAuthenticationType = jitsiWellKnown.authenticationType

            XCTAssertNotNil(jistiAuthenticationType)
            
            XCTAssertEqual(jistiAuthenticationType, .other(expectedAuthenticationTypeString))
        } catch {
            XCTFail("Fail with error: \(error)")
        }
    }
}
