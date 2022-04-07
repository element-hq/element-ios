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
