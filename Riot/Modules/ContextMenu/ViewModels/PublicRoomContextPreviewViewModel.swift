// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// `PublicRoomContextPreviewViewModel` provides the data to the `RoomContextPreviewViewController` from an instance of `MXPublicRoom`
class PublicRoomContextPreviewViewModel: RoomContextPreviewViewModelProtocol {
    
    // MARK: - Properties
    
    private let publicRoom: MXPublicRoom
    weak var viewDelegate: RoomContextPreviewViewModelViewDelegate?
    
    // MARK: - Setup
    
    init(publicRoom: MXPublicRoom) {
        self.publicRoom = publicRoom
    }
    
    // MARK: - RoomContextPreviewViewModelProtocol
    
    func process(viewAction: RoomContextPreviewViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        }
    }
    
    // MARK: - Private
    
    private func loadData() {
        let mapper = MXRoomTypeMapper(defaultRoomType: .room)
        let parameters = RoomContextPreviewLoadedParameters(
            roomId: publicRoom.roomId,
            roomType: mapper.roomType(from: publicRoom.roomTypeString),
            displayName: publicRoom.name,
            topic: publicRoom.topic,
            avatarUrl: publicRoom.avatarUrl,
            joinRule: .none,
            membership: .unknown,
            inviterId: nil,
            inviter: nil,
            membersCount: publicRoom.numJoinedMembers)
        self.viewDelegate?.roomContextPreviewViewModel(self, didUpdateViewState: .loaded(parameters))
    }
}
