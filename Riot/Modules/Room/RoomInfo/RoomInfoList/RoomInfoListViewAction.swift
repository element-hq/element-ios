// File created from ScreenTemplate
// $ createScreen.sh Room2/RoomInfo RoomInfoList
/*
 Copyright 2020 New Vector Ltd
 
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

enum RoomInfoListTarget: Equatable {
    case settings(_ field: RoomSettingsViewControllerField = RoomSettingsViewControllerFieldNone)
    case members
    case uploads
    case integrations
    case search

    var tabIndex: UInt {
        let tabIndex: UInt
        
        switch self {
        case .members:
            tabIndex = 0
        case .uploads:
            tabIndex = 1
        case .settings:
            tabIndex = 2
        case .integrations:
            tabIndex = 3
        case .search:
            tabIndex = 4
        }
        
        return tabIndex
    }
}

/// RoomInfoListViewController view actions exposed to view model
enum RoomInfoListViewAction {
    case loadData
    case navigate(target: RoomInfoListTarget)
    case leave
    case cancel
}
