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

/// SpaceExploreRoomViewController view state
enum SpaceExploreRoomViewState {
    case loading
    case spaceNameFound(_ spaceName: String)
    case loaded(_ children: [SpaceExploreRoomListItemViewData], _ hasMore: Bool)
    case canJoin(Bool)
    case emptySpace
    case emptyFilterResult
    case error(Error)
}
