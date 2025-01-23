// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
