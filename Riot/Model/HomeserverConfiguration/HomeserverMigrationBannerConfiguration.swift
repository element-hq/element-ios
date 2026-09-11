// 
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// `HomeserverMigrationBannerConfiguration` gives the resolved configuration of the banner inviting users
/// to migrate to the new app, based on the `io.element.migration_banner` Well Known section and the default values.
@objcMembers
final class HomeserverMigrationBannerConfiguration: NSObject {
    /// Indicate if the banner is enabled for this homeserver.
    /// Note: this doesn't take into account a potential dismissal of the banner by the user.
    let isEnabled: Bool
    /// Title of the banner.
    let title: String
    /// Body of the banner. `https://` URLs it contains are rendered as links.
    let body: String
    /// Label of the download button.
    let buttonText: String
    /// App Store ID (a.k.a. iTunes item identifier) of the app the download button points to.
    /// `nil` when no download button should be displayed.
    let targetAppStoreID: String?
    /// Indicate if the download button points to the default replacement app rather than a custom one.
    let isTargetDefaultReplacementApp: Bool
    
    init(isEnabled: Bool,
         title: String,
         body: String,
         buttonText: String,
         targetAppStoreID: String?,
         isTargetDefaultReplacementApp: Bool) {
        self.isEnabled = isEnabled
        self.title = title
        self.body = body
        self.buttonText = buttonText
        self.targetAppStoreID = targetAppStoreID
        self.isTargetDefaultReplacementApp = isTargetDefaultReplacementApp
        
        super.init()
    }
}
