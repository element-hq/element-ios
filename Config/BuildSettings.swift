// 
// Copyright 2020 Vector Creations Ltd
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

/// BuildSettings provides settings computed at build time.
/// In future, it may be automatically generated from xcconfig files
@objcMembers
final class BuildSettings: NSObject {
    
    // MARK: - Bundle Settings
    static var bundleDisplayName: String {
        Bundle.app.object(forInfoDictionaryKey: "CFBundleDisplayName") as! String
    }
    
    static var applicationGroupIdentifier: String {
        Bundle.app.object(forInfoDictionaryKey: "applicationGroupIdentifier") as! String
    }
    
    
    // MARK: - Legal URLs
    static let applicationCopyrightUrlString = "https://element.io/copyright"
    static let applicationPrivacyPolicyUrlString = "https://element.io/privacy"
    static let applicationTermsConditionsUrlString = "https://element.io/terms-of-service"
    
    
    // MARK: - VoIP
    static var allowVoIPUsage: Bool {
        #if canImport(JitsiMeet)
        return true
        #else
        return false
        #endif
    }
    static let stunServerFallbackUrlString: String? = "stun:turn.matrix.org"
    
    
    // List of homeservers for the public rooms directory
    static let roomDirectoryServers = [
        "matrix.org"
    ]
    
    
    // Analytics
    static let analyticsServerUrl = URL(string: "https://piwik.riot.im/piwik.php")
    static let analyticsAppId = "14"
    
    
    // MARK: - Bug report
    static let bugReportEndpointUrlString = "https://riot.im/bugreports"
    // Use the name allocated by the bug report server
    static let bugReportApplicationId = "riot-ios"

    
    // MARK: - Features
    
    /// Setting to force protection by pin code
    static let forcePinProtection: Bool = false
    
    /// Force non-jailbroken app usage
    static let forceNonJailbrokenUsage: Bool = true
    
    
    // MARK: - Screen settings -
    
    static let showUserFirstNameInSettings: Bool = false
    static let showUserSurnameInSettings: Bool = false
    static let allowAddingEmailThreepids: Bool = true
    static let allowAddingPhoneThreepids: Bool = true
    static let showThreepidExplanatory: Bool = true
    static let showDiscoverySettings: Bool = true
    static let allowIdentityServerConfig: Bool = true
    static let allowLocalContactsAccess: Bool = true
    static let showAdvancedSettings: Bool = true
    static let showLabSettings: Bool = true
    static let allowChangingRageshakeSettings: Bool = true
    static let allowChangingCrashUsageDataSettings: Bool = true
    static let allowBugReportingManually: Bool = true
    static let allowDeactivatingAccount: Bool = true
    static let allowSendingStickers: Bool = true
    
    
    // MARK: - Message
    static let allowMessageDetailsShare: Bool = true
    static let allowMessageDetailsPermalink: Bool = true
    static let allowMessageDetailsViewSource: Bool = true
    
    
    // MARK: - Authentication Screen
    static let authScreenShowRegister = true
    static let authScreenShowCustomServerOptions = true
}
