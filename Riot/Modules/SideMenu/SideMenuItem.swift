// 
// Copyright 2021 New Vector Ltd
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

/// SideMenuItem represents side menu actions
enum SideMenuItem {
    case about
    case inviteFriends
    case news
    case jobs
    case profile
    case settings
    case help
}

extension SideMenuItem {
    
    var title: String {
        let title: String
        
        switch self {
        case .inviteFriends:
            title = VectorL10n.sideMenuActionInviteFriends
        case .settings:
            title = VectorL10n.sideMenuActionSettings
        case .help:
            title = VectorL10n.sideMenuActionHelp
        case .profile:
            title = "Profile"
        case .news:
            title = "News"
        case .jobs:
            title = "Jobs"
        case .about:
            title = "About"
        }
        
        return title
    }
    
    var icon: UIImage {
        //        let icon: UIImage
        var icon: UIImage = Asset.Images.sideMenuActionIconShare.image
        
        switch self {
        case .inviteFriends:
            icon = Asset.Images.sideMenuActionIconShare.image
        case .settings:
            icon = Asset.Images.sideMenuActionIconSettings.image
        case .help:
            icon = Asset.Images.sideMenuActionIconHelp.image
            //        case .feedback:
            //            icon = Asset.Images.sideMenuActionIconFeedback.image
        case .profile:
            if #available(iOS 13.0, *) {
                icon = UIImage(systemName: "person.fill") ?? Asset.Images.sideMenuActionIconShare.image
            } else {
                // Fallback on earlier versions
            }
        case .news:
            if #available(iOS 13.0, *) {
                icon = UIImage(systemName: "newspaper") ?? Asset.Images.sideMenuActionIconShare.image
            } else {
                // Fallback on earlier versions
            }
        case .jobs:
            if #available(iOS 13.0, *) {
                icon = UIImage(systemName: "briefcase.fill") ?? Asset.Images.sideMenuActionIconShare.image
            } else {
                // Fallback on earlier versions
            }
        case .about:
            if #available(iOS 13.0, *) {
                icon = UIImage(systemName: "at") ?? Asset.Images.sideMenuActionIconShare.image
            } else {
                // Fallback on earlier versions
            }
        }
            
        return icon
    }
}

