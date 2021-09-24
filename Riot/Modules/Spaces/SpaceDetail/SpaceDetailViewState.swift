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

struct SpaceDetailLoadedParameters {
    let spaceId: String
    let displayName: String?
    let topic: String?
    let avatarUrl: String?
    let joinRule: MXRoomJoinRule?
    let membership: MXMembership
    let inviterId: String?
    let inviter: MXUser?
    let membersCount: UInt
}

/// SpaceDetailViewController view state
enum SpaceDetailViewState {
    case loading
    case loaded(_ paremeters: SpaceDetailLoadedParameters)
    case error(Error)
}
