// 
// Copyright 2020 New Vector Ltd
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
