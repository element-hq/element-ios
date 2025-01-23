// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// `SpaceChildContextPreviewViewModel` provides the data to the `RoomContextPreviewViewController` from an instance of `MXSpaceChildInfo`
class SpaceChildContextPreviewViewModel: RoomContextPreviewViewModelProtocol {
    
    // MARK: - Properties
    
    private let childInfo: MXSpaceChildInfo
    weak var viewDelegate: RoomContextPreviewViewModelViewDelegate?
    
    // MARK: - Setup
    
    init(childInfo: MXSpaceChildInfo) {
        self.childInfo = childInfo
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
        let parameters = RoomContextPreviewLoadedParameters(
            roomId: childInfo.childRoomId,
            roomType: childInfo.roomType,
            displayName: childInfo.displayName,
            topic: childInfo.topic,
            avatarUrl: childInfo.avatarUrl,
            joinRule: .none,
            membership: .unknown,
            inviterId: nil,
            inviter: nil,
            membersCount: childInfo.activeMemberCount)
        self.viewDelegate?.roomContextPreviewViewModel(self, didUpdateViewState: .loaded(parameters))
    }
}
