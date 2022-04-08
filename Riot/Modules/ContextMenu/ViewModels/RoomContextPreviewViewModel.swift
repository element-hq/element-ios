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

/// `RoomContextPreviewViewModel` provides the data to the `RoomContextPreviewViewController` from an instance of `MXRoom`
class RoomContextPreviewViewModel: RoomContextPreviewViewModelProtocol {
    
    // MARK: - Properties
    
    private let room: MXRoom
    weak var viewDelegate: RoomContextPreviewViewModelViewDelegate?
    
    // MARK: - Setup
    
    init(room: MXRoom) {
        self.room = room
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
            roomId: self.room.roomId,
            roomType: self.room.summary?.roomType ?? .none,
            displayName: self.room.displayName,
            topic: self.room.summary?.topic,
            avatarUrl: self.room.summary?.avatar,
            joinRule: .public,
            membership: self.room.summary?.membership ?? .unknown,
            inviterId: nil,
            inviter: nil,
            membersCount: 0)
        self.viewDelegate?.roomContextPreviewViewModel(self, didUpdateViewState: .loaded(parameters))

        room.state { roomState in
            let membersCount = roomState?.members.joinedMembers.count ?? 0

            var inviteEvent: MXEvent?
            roomState?.stateEvents.forEach({ event in
                guard let membership = event.wireContent["membership"] as? String, membership == "invite", event.stateKey == self.room.mxSession.myUserId else {
                    return
                }

                inviteEvent = event
            })
            
            let inviter: MXUser?
            if let inviterId = inviteEvent?.sender {
                inviter = self.room.mxSession.user(withUserId: inviterId)
            } else {
                inviter = nil
            }
            
            let parameters = RoomContextPreviewLoadedParameters(
                roomId: self.room.roomId,
                roomType: self.room.summary?.roomType ?? .none,
                displayName: self.room.displayName,
                topic: roomState?.topic,
                avatarUrl: roomState?.avatar,
                joinRule: roomState?.joinRule,
                membership: self.room.summary?.membership ?? .unknown,
                inviterId: inviteEvent?.sender,
                inviter: inviter,
                membersCount: membersCount)
            self.viewDelegate?.roomContextPreviewViewModel(self, didUpdateViewState: .loaded(parameters))
        }
    }
}
