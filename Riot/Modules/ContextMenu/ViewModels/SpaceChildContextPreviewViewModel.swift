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
