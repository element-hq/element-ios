// 
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import Element

/// Tests the resolution of the migration banner configuration from the homeserver Well Known.
class HomeserverMigrationBannerConfigurationTests: XCTestCase {
    
    private let startDate = BuildSettings.migrationBannerShowWhenNotConfiguredStartDate
    private lazy var beforeStartDate = startDate.addingTimeInterval(-1)
    private lazy var afterStartDate = startDate.addingTimeInterval(24 * 60 * 60)
    
    // MARK: - Helpers
    
    private func buildConfiguration(migrationBannerSection: Any?, now: Date) -> HomeserverMigrationBannerConfiguration {
        var wellKnownDictionary: [String: Any] = [
            "m.homeserver": [
                "base_url": "https://your.homeserver.org"
            ]
        ]
        if let migrationBannerSection = migrationBannerSection {
            wellKnownDictionary["io.element.migration_banner"] = migrationBannerSection
        }
        
        let wellKnown = MXWellKnown(fromJSON: wellKnownDictionary)
        return HomeserverConfigurationBuilder(currentDateProvider: { now }).build(from: wellKnown).migrationBanner
    }
    
    // MARK: - Tests
    
    func testStartDate() {
        let formatter = ISO8601DateFormatter()
        XCTAssertEqual(formatter.string(from: startDate), "2026-11-15T00:00:00Z")
    }
    
    func testMissingSectionBeforeStartDateIsDisabled() {
        XCTAssertFalse(buildConfiguration(migrationBannerSection: nil, now: beforeStartDate).isEnabled)
    }
    
    func testMissingSectionFromStartDateIsEnabled() {
        XCTAssertTrue(buildConfiguration(migrationBannerSection: nil, now: startDate).isEnabled)
        XCTAssertTrue(buildConfiguration(migrationBannerSection: nil, now: afterStartDate).isEnabled)
    }
    
    func testMissingWellKnownFollowsStartDate() {
        XCTAssertFalse(HomeserverConfigurationBuilder(currentDateProvider: { self.beforeStartDate }).build(from: nil).migrationBanner.isEnabled)
        XCTAssertTrue(HomeserverConfigurationBuilder(currentDateProvider: { self.afterStartDate }).build(from: nil).migrationBanner.isEnabled)
    }
    
    func testEmptySectionIsEnabledWhateverTheDate() {
        XCTAssertTrue(buildConfiguration(migrationBannerSection: [String: Any](), now: beforeStartDate).isEnabled)
        XCTAssertTrue(buildConfiguration(migrationBannerSection: [String: Any](), now: afterStartDate).isEnabled)
    }
    
    func testExplicitlyEnabledBeforeStartDate() {
        XCTAssertTrue(buildConfiguration(migrationBannerSection: ["enabled": true], now: beforeStartDate).isEnabled)
    }
    
    func testExplicitlyDisabledAfterStartDate() {
        XCTAssertFalse(buildConfiguration(migrationBannerSection: ["enabled": false], now: afterStartDate).isEnabled)
    }
    
    // MARK: Content
    
    func testDefaultContent() {
        let configuration = buildConfiguration(migrationBannerSection: [String: Any](), now: beforeStartDate)
        
        XCTAssertEqual(configuration.title, VectorL10n.migrationBannerTitle)
        XCTAssertEqual(configuration.body, VectorL10n.migrationBannerBody)
        XCTAssertEqual(configuration.buttonText, VectorL10n.migrationBannerDownloadButton)
        XCTAssertEqual(configuration.targetAppStoreID, BuildSettings.replacementApp?.productID)
        XCTAssertTrue(configuration.isTargetDefaultReplacementApp)
    }
    
    func testMissingSectionUsesDefaultContent() {
        let configuration = buildConfiguration(migrationBannerSection: nil, now: afterStartDate)
        
        XCTAssertEqual(configuration.title, VectorL10n.migrationBannerTitle)
        XCTAssertEqual(configuration.body, VectorL10n.migrationBannerBody)
        XCTAssertEqual(configuration.buttonText, VectorL10n.migrationBannerDownloadButton)
        XCTAssertEqual(configuration.targetAppStoreID, BuildSettings.replacementApp?.productID)
        XCTAssertTrue(configuration.isTargetDefaultReplacementApp)
    }
    
    func testCustomContent() {
        let section: [String: Any] = [
            "title": "Time to move",
            "body": "Get the new app at https://element.io/download",
            "button_text": "Get Element Pro",
            "target_app_id_ios": "123456789"
        ]
        
        let configuration = buildConfiguration(migrationBannerSection: section, now: beforeStartDate)
        
        XCTAssertTrue(configuration.isEnabled)
        XCTAssertEqual(configuration.title, "Time to move")
        XCTAssertEqual(configuration.body, "Get the new app at https://element.io/download")
        XCTAssertEqual(configuration.buttonText, "Get Element Pro")
        XCTAssertEqual(configuration.targetAppStoreID, "123456789")
        XCTAssertFalse(configuration.isTargetDefaultReplacementApp)
    }
    
    func testBlankContentUsesDefaults() {
        let section: [String: Any] = [
            "title": "  ",
            "body": "",
            "button_text": "\n"
        ]
        
        let configuration = buildConfiguration(migrationBannerSection: section, now: beforeStartDate)
        
        XCTAssertEqual(configuration.title, VectorL10n.migrationBannerTitle)
        XCTAssertEqual(configuration.body, VectorL10n.migrationBannerBody)
        XCTAssertEqual(configuration.buttonText, VectorL10n.migrationBannerDownloadButton)
    }
    
    func testBlankTargetAppIDHidesTheButton() {
        let configuration = buildConfiguration(migrationBannerSection: ["target_app_id_ios": "", "button_text": "Get it"], now: beforeStartDate)
        
        XCTAssertNil(configuration.targetAppStoreID)
        XCTAssertFalse(configuration.isTargetDefaultReplacementApp)
    }
    
    func testExplicitDefaultTargetAppIDIsRecognised() throws {
        let defaultTargetAppStoreID = try XCTUnwrap(BuildSettings.replacementApp?.productID)
        let configuration = buildConfiguration(migrationBannerSection: ["target_app_id_ios": defaultTargetAppStoreID], now: beforeStartDate)
        
        XCTAssertEqual(configuration.targetAppStoreID, defaultTargetAppStoreID)
        XCTAssertTrue(configuration.isTargetDefaultReplacementApp)
    }
    
    // MARK: Invalid values
    
    func testInvalidSectionIsTreatedAsMissing() {
        XCTAssertFalse(buildConfiguration(migrationBannerSection: "not an object", now: beforeStartDate).isEnabled)
        XCTAssertTrue(buildConfiguration(migrationBannerSection: "not an object", now: afterStartDate).isEnabled)
        XCTAssertFalse(buildConfiguration(migrationBannerSection: ["enabled": "false"], now: beforeStartDate).isEnabled)
        XCTAssertTrue(buildConfiguration(migrationBannerSection: ["enabled": "false"], now: afterStartDate).isEnabled)
    }
}
