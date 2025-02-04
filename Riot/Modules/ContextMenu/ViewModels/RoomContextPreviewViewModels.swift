// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
