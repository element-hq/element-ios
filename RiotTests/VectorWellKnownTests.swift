// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import Element

class VectorWellKnownTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK: - Tests
    
    func testVectorWellKnownParsing() {
        
        let expectedJitsiServer = "your.jitsi.example.org"
        let expectedE2EEEByDefaultEnabled = false
        
        let wellKnownDictionary: [String: Any] = [
            "im.vector.riot.e2ee" : [
                "default" : expectedE2EEEByDefaultEnabled
            ],
            "im.vector.riot.jitsi" : [
                "preferredDomain" : expectedJitsiServer
            ],
            "io.element.e2ee" : [
                "default" : expectedE2EEEByDefaultEnabled
            ],
            "io.element.jitsi" : [
                "preferredDomain" : expectedJitsiServer
            ]
        ]
                        
        let serializationService = SerializationService()
                            
        do {
            let vectorWellKnown: VectorWellKnown = try serializationService.deserialize(wellKnownDictionary)
            
            let jistiConfiguration = vectorWellKnown.jitsi
            let encryptionConfiguration = vectorWellKnown.encryption
            
            XCTAssertNotNil(jistiConfiguration)
            XCTAssertNotNil(encryptionConfiguration)
            
            XCTAssertEqual(jistiConfiguration?.preferredDomain, expectedJitsiServer)
            XCTAssertEqual(encryptionConfiguration?.isE2EEByDefaultEnabled, expectedE2EEEByDefaultEnabled)
                        
            let deprecatedJistiConfiguration = vectorWellKnown.deprecatedJitsi
            let deprecatedEncryptionConfiguration = vectorWellKnown.deprecatedEncryption
            
            XCTAssertNotNil(deprecatedJistiConfiguration)
            XCTAssertNotNil(deprecatedEncryptionConfiguration)
            
            XCTAssertEqual(deprecatedJistiConfiguration?.preferredDomain, expectedJitsiServer)
            XCTAssertEqual(deprecatedEncryptionConfiguration?.isE2EEByDefaultEnabled, expectedE2EEEByDefaultEnabled)
            
        } catch {
            XCTFail("Fail with error: \(error)")
        }
    }        
    
    func testVectorWellKnownParsingMissingKey() {
                
        let expectedE2EEEByDefaultEnabled = false
        
        let wellKnownDictionary: [String: Any] = [
            "io.element.e2ee" : [
                "default" : expectedE2EEEByDefaultEnabled
            ]
        ]
                        
        let serializationService = SerializationService()
                            
        do {
            let vectorWellKnown: VectorWellKnown = try serializationService.deserialize(wellKnownDictionary)
            
            XCTAssertNil(vectorWellKnown.jitsi)
            XCTAssertNotNil(vectorWellKnown.encryption)
                        
            XCTAssertEqual(vectorWellKnown.encryption?.isE2EEByDefaultEnabled, expectedE2EEEByDefaultEnabled)
        } catch {
            XCTFail("Fail with error: \(error)")
        }
    }
}
