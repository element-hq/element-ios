/*
 Copyright 2019 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
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
