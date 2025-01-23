//
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import Element

class HomeserverConfigurationTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK: - Tests
    
    func testHomeserverConfigurationBuilder() {
    
        let expectedJitsiServer = "your.jitsi.example.org"
        let expectedJitsiServerStringURL = "https://\(expectedJitsiServer)"
        let expectedDeprecatedJitsiServer = "your.deprecated.jitsi.example.org"
        let expectedE2EEEByDefaultEnabled = true
        let expectedDeprecatedE2EEEByDefaultEnabled = false
        let expectedMapStyleURLString = "https://your.tileserver.org/style.json"
        let expectedSecureBackupRequired = true
        let secureBackupSetupMethods = ["passphrase"]
        let expectedSecureBackupSetupMethods: [VectorWellKnownBackupSetupMethod] = [.passphrase]
        let outboundKeysPreSharingMode = "on_room_opening"
        let expectedOutboundKeysPreSharingMode: MXKKeyPreSharingStrategy = .whenEnteringRoom
    
        let wellKnownDictionary: [String: Any] = [
            "m.homeserver": [
                 "base_url": "https://your.homeserver.org"
            ],
             "m.identity_server": [
                 "base_url": "https://your.identity-server.org"
            ],
            "m.tile_server": [
                 "map_style_url": expectedMapStyleURLString
            ],
            "im.vector.riot.e2ee" : [
                "default" : expectedDeprecatedE2EEEByDefaultEnabled
            ],
            "im.vector.riot.jitsi" : [
                "preferredDomain" : expectedDeprecatedJitsiServer
            ],
            "io.element.e2ee" : [
                "default" : expectedE2EEEByDefaultEnabled,
                "secure_backup_required": expectedSecureBackupRequired,
                "secure_backup_setup_methods": secureBackupSetupMethods,
                "outbound_keys_pre_sharing_mode": outboundKeysPreSharingMode
            ],
            "io.element.jitsi" : [
                "preferredDomain" : expectedJitsiServer
            ]
        ]
        
        let wellKnown = MXWellKnown(fromJSON: wellKnownDictionary)
        
        let homeserverConfigurationBuilder = HomeserverConfigurationBuilder()
        let homeserverConfiguration = homeserverConfigurationBuilder.build(from: wellKnown)
    
        XCTAssertEqual(homeserverConfiguration.jitsi.serverDomain, expectedJitsiServer)
        XCTAssertEqual(homeserverConfiguration.jitsi.serverURL?.absoluteString, expectedJitsiServerStringURL)
        XCTAssertEqual(homeserverConfiguration.encryption.isE2EEByDefaultEnabled, expectedE2EEEByDefaultEnabled)
        XCTAssertEqual(homeserverConfiguration.encryption.isSecureBackupRequired, expectedSecureBackupRequired)
        XCTAssertEqual(homeserverConfiguration.encryption.secureBackupSetupMethods, expectedSecureBackupSetupMethods)
        XCTAssertEqual(homeserverConfiguration.encryption.outboundKeysPreSharingMode, expectedOutboundKeysPreSharingMode)
        
        XCTAssertEqual(homeserverConfiguration.tileServer.mapStyleURL.absoluteString, expectedMapStyleURLString)
    }

    func testHomeserverEncryptionConfigurationDefaults() {

        let expectedE2EEEByDefaultEnabled = true
        let expectedSecureBackupRequired = false
        let expectedSecureBackupSetupMethods: [VectorWellKnownBackupSetupMethod] = [.passphrase, .key]
        let expectedOutboundKeysPreSharingMode: MXKKeyPreSharingStrategy = .whenTyping

        let wellKnownDictionary: [String: Any] = [
            "m.homeserver": [
                 "base_url": "https://your.homeserver.org"
            ],
             "m.identity_server": [
                 "base_url": "https://your.identity-server.org"
            ]
        ]

        let wellKnown = MXWellKnown(fromJSON: wellKnownDictionary)

        let homeserverConfigurationBuilder = HomeserverConfigurationBuilder()
        let homeserverConfiguration = homeserverConfigurationBuilder.build(from: wellKnown)

        XCTAssertEqual(homeserverConfiguration.encryption.isE2EEByDefaultEnabled, expectedE2EEEByDefaultEnabled)
        XCTAssertEqual(homeserverConfiguration.encryption.isSecureBackupRequired, expectedSecureBackupRequired)
        XCTAssertEqual(homeserverConfiguration.encryption.secureBackupSetupMethods, expectedSecureBackupSetupMethods)
        XCTAssertEqual(homeserverConfiguration.encryption.outboundKeysPreSharingMode, expectedOutboundKeysPreSharingMode)
    }
}
