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
    
    func testMigrationBannerParsing() {
        let wellKnownDictionary: [String: Any] = [
            "io.element.e2ee": [
                "default": false
            ],
            "io.element.migration_banner": [
                "enabled": false
            ]
        ]
        
        do {
            let vectorWellKnown: VectorWellKnown = try SerializationService().deserialize(wellKnownDictionary)
            XCTAssertEqual(vectorWellKnown.migrationBanner?.isEnabled, false)
            XCTAssertEqual(vectorWellKnown.encryption?.isE2EEByDefaultEnabled, false)
        } catch {
            XCTFail("Fail with error: \(error)")
        }
    }
    
    func testMigrationBannerParsingContent() {
        let wellKnownDictionary: [String: Any] = [
            "io.element.migration_banner": [
                "title": "Time to move",
                "body": "Get the new app at https://element.io/download",
                "button_text": "Get Element Pro",
                "target_app_id_ios": "123456789"
            ]
        ]
        
        do {
            let vectorWellKnown: VectorWellKnown = try SerializationService().deserialize(wellKnownDictionary)
            let migrationBanner = vectorWellKnown.migrationBanner
            XCTAssertNil(migrationBanner?.isEnabled)
            XCTAssertEqual(migrationBanner?.title, "Time to move")
            XCTAssertEqual(migrationBanner?.body, "Get the new app at https://element.io/download")
            XCTAssertEqual(migrationBanner?.buttonText, "Get Element Pro")
            XCTAssertEqual(migrationBanner?.targetAppID, "123456789")
        } catch {
            XCTFail("Fail with error: \(error)")
        }
    }
    
    func testMigrationBannerParsingEmptySection() {
        let wellKnownDictionary: [String: Any] = [
            "io.element.migration_banner": [String: Any]()
        ]
        
        do {
            let vectorWellKnown: VectorWellKnown = try SerializationService().deserialize(wellKnownDictionary)
            XCTAssertNotNil(vectorWellKnown.migrationBanner)
            XCTAssertNil(vectorWellKnown.migrationBanner?.isEnabled)
        } catch {
            XCTFail("Fail with error: \(error)")
        }
    }
    
    func testMigrationBannerParsingMissingSection() {
        let wellKnownDictionary: [String: Any] = [
            "io.element.e2ee": [
                "default": false
            ]
        ]
        
        do {
            let vectorWellKnown: VectorWellKnown = try SerializationService().deserialize(wellKnownDictionary)
            XCTAssertNil(vectorWellKnown.migrationBanner)
        } catch {
            XCTFail("Fail with error: \(error)")
        }
    }
    
    func testMigrationBannerParsingInvalidEnabledValueFails() {
        let wellKnownDictionary: [String: Any] = [
            "io.element.migration_banner": [
                "enabled": "false"
            ]
        ]
        
        XCTAssertThrowsError(try SerializationService().deserialize(wellKnownDictionary) as VectorWellKnown)
    }
    
    func testMigrationBannerParsingInvalidSectionFails() {
        let wellKnownDictionary: [String: Any] = [
            "io.element.migration_banner": "not an object"
        ]
        
        XCTAssertThrowsError(try SerializationService().deserialize(wellKnownDictionary) as VectorWellKnown)
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
