// 
// Copyright 2022 New Vector Ltd
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

/// All the data potentially loaded by the `RoomContextPreviewViewModelProtocol` to the `RoomContextPreviewViewController`
struct RoomContextPreviewLoadedParameters {
    let roomId: String
    let roomType: MXRoomType
    let displayName: String?
    let topic: String?
    let avatarUrl: String?
    let joinRule: MXRoomJoinRule?
    let membership: MXMembership
    let inviterId: String?
    let inviter: MXUser?
    let membersCount: Int
}

/// `RoomContextPreviewViewController` view state
enum RoomContextPreviewViewState {
    case loaded(_ paremeters: RoomContextPreviewLoadedParameters)
}

/// `RoomContextPreviewViewController` view action
enum RoomContextPreviewViewAction {
    case loadData
}

/// View delegate for `RoomContextPreviewViewModelProtocol`
protocol RoomContextPreviewViewModelViewDelegate: AnyObject {
    func roomContextPreviewViewModel(_ viewModel: RoomContextPreviewViewModelProtocol, didUpdateViewState viewSate: RoomContextPreviewViewState)
}

/// Classes compliant with `RoomContextPreviewViewModelProtocol` are meant to provide the data to the `RoomContextPreviewViewController`
protocol RoomContextPreviewViewModelProtocol {
    var viewDelegate: RoomContextPreviewViewModelViewDelegate? { get set }
    func process(viewAction: RoomContextPreviewViewAction)
}
