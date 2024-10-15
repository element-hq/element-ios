/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

/// View model used by `WidgetPermissionViewController`
@objcMembers
final class WidgetPermissionViewModel: NSObject {
    
    // MARK: - Properties
    
    let creatorUserId: String
    let creatorDisplayName: String?
    let creatorAvatarUrl: String?
    let widgetDomain: String?
    let isWebviewWidget: Bool
    let widgetPermissions: [String]
    let mediaManager: MXMediaManager
    
    lazy var permissionsInformationText: String = {
        return self.buildPermissionsInformationText()
    }()
    
    // MARK: - Setup
    
    init(creatorUserId: String, creatorDisplayName: String?, creatorAvatarUrl: String?, widgetDomain: String?, isWebviewWidget: Bool, widgetPermissions: [String], mediaManager: MXMediaManager) {
        self.creatorUserId = creatorUserId
        self.creatorDisplayName = creatorDisplayName
        self.creatorAvatarUrl = creatorAvatarUrl
        self.widgetDomain = widgetDomain
        self.isWebviewWidget = isWebviewWidget
        self.widgetPermissions = widgetPermissions
        self.mediaManager = mediaManager
    }
    
    // MARK: - Private
    
    private func buildPermissionsInformationText() -> String {
        
        let informationTitle: String
        let widgetDomain = self.widgetDomain ?? ""
        
        if self.isWebviewWidget {
            informationTitle = VectorL10n.roomWidgetPermissionWebviewInformationTitle(widgetDomain)
        } else {
            informationTitle = VectorL10n.roomWidgetPermissionInformationTitle(widgetDomain)
        }
        
        let permissionsList = self.widgetPermissions.reduce("") { (accumulatedPermissions, permission) -> String in
            return accumulatedPermissions + "\n• \(permission)"
        }
        
        return informationTitle + permissionsList
    }
}
