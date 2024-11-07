/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

/// A structure used to handle the application version
@objcMembers
final class AppVersion: NSObject {

    // MARK: - Constants

    private enum Constants {
        static let lastBundleShortVersion: String = "lastBundleShortVersion"
        static let lastBundleVersion: String = "lastBundleVersion"
        static let shortVersionComponentsSeparator: Character = "."
    }
    
    // Current app version from Info.plist
    static var current: AppVersion? {
        guard let bundleShortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            let bundleVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String else {
                return nil
        }
        return AppVersion(bundleShortVersion: bundleShortVersion, bundleVersion: bundleVersion)
    }
    
    // Last app version used by user
    static var lastUsed: AppVersion? {
        guard let bundleShortVersion = UserDefaults.standard.string(forKey: Constants.lastBundleShortVersion),
            let bundleVersion = UserDefaults.standard.string(forKey: Constants.lastBundleVersion) else {
                return nil
        }
        return AppVersion(bundleShortVersion: bundleShortVersion, bundleVersion: bundleVersion)
    }

    // MARK: - Properties

    let bundleShortVersion: String
    let bundleVersion: String

    // MARK: - Setup
    
    init(bundleShortVersion: String, bundleVersion: String) {
        self.bundleShortVersion = bundleShortVersion
        self.bundleVersion = bundleVersion
        super.init()
    }

    // MARK: - Public
    
    func compare(_ appVersion: AppVersion) -> ComparisonResult {
        
        let appVersionComparisonResult: ComparisonResult
        
        let bundleShortVersionComparisonResult = AppVersion.compare(stringVersion: self.bundleShortVersion, with: appVersion.bundleShortVersion)
        
        // If short versions are equal compare build version
        if bundleShortVersionComparisonResult == ComparisonResult.orderedSame {
            appVersionComparisonResult = AppVersion.compare(stringVersion: self.bundleVersion, with: appVersion.bundleVersion)
        } else {
            appVersionComparisonResult = bundleShortVersionComparisonResult
        }
        
        return appVersionComparisonResult
    }

    /// Return true if the last stored version is lower than the provided one.
    /// Retrun true by default when there is no stored version.
    static func isLastUsedVersionLowerThan(_ appVersion: AppVersion) -> Bool {
        guard let lastAppVersion = AppVersion.lastUsed else {
            return true
        }
        return lastAppVersion.compare(appVersion) == .orderedAscending
    }

    /// Store the current application version.
    static func updateLastUsedVersion() {
        guard let currentVersion = AppVersion.current else {
            return
        }
        UserDefaults.standard.set(currentVersion.bundleShortVersion, forKey: Constants.lastBundleShortVersion)
        UserDefaults.standard.set(currentVersion.bundleVersion, forKey: Constants.lastBundleVersion)
    }
    
    override var description: String {
        return "\(bundleShortVersion)(\(bundleVersion))"
    }

    // MARK: - Private

    private static func compare(stringVersion: String, with otherStringVersion: String) -> ComparisonResult {
        return stringVersion.compare(otherStringVersion, options: NSString.CompareOptions.numeric, range: nil, locale: nil)
    }
}
