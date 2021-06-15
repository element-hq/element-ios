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

class PublicRoomsDirectoryViewModel {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let dataSource: PublicRoomsDirectoryDataSource
    private let session: MXSession
     
    // MARK: Public
    
    var roomsCount: Int {
        return Int(dataSource.roomsCount)
    }
    
    var directoryServerDisplayname: String? {
        return dataSource.directoryServerDisplayname
    }
    
    // MARK: - Setup
    
    init(dataSource: PublicRoomsDirectoryDataSource, session: MXSession) {
        self.dataSource = dataSource
        self.session = session
    }
    
    // MARK: - Public
    
    func roomViewModel(at row: Int) -> DirectoryRoomTableViewCellVM? {
        self.roomViewModel(at: IndexPath(row: row, section: 0))
    }
    
    func roomViewModel(at indexPath: IndexPath) -> DirectoryRoomTableViewCellVM? {
        guard let publicRoom = dataSource.room(at: indexPath) else { return nil }
        return self.roomCellViewModel(with: publicRoom)
    }
    
    // MARK: - Private
    
    private func roomCellViewModel(with publicRoom: MXPublicRoom) -> DirectoryRoomTableViewCellVM {
        let summary = session.roomSummary(withRoomId: publicRoom.roomId)
        
        let isJoined = summary?.membership == .join || summary?.membershipTransitionState == .joined
        
        return DirectoryRoomTableViewCellVM(title: publicRoom.displayname(),
                                            numberOfUsers: publicRoom.numJoinedMembers,
                                            subtitle: MXTools.stripNewlineCharacters(publicRoom.topic),
                                            isJoined: isJoined,
                                            roomId: publicRoom.roomId,
                                            avatarUrl: publicRoom.avatarUrl,
                                            mediaManager: session.mediaManager)
    }
}
