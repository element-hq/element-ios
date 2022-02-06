// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceRoomList/ExploreRoom ShowSpaceExploreRoom
/*
 Copyright 2021 New Vector Ltd
 
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

/// SpaceExploreRoomViewController view actions exposed to view model
enum SpaceExploreRoomViewAction {
    case reloadData
    case loadData
    case complete(_ selectedItem: SpaceExploreRoomListItemViewData, _ sourceView: UIView?)
    case searchChanged(_ text: String?)
    case joinOpenedSpace
    case cancel
    case addRoom
    case inviteTo(_ item: SpaceExploreRoomListItemViewData)
    case revertSuggestion(_ item: SpaceExploreRoomListItemViewData)
    case settings(_ item: SpaceExploreRoomListItemViewData)
    case removeChild(_ item: SpaceExploreRoomListItemViewData)
    case join(_ item: SpaceExploreRoomListItemViewData)
}
