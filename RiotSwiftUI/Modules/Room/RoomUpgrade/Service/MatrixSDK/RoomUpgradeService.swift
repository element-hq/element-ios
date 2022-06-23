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
import Combine
import MatrixSDK

class RoomUpgradeService: RoomUpgradeServiceProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let parentSpaceId: String?
    private let versionOverride: String
    private var currentOperation: MXHTTPOperation?
    private var didBuildSpaceGraphObserver: Any?

    // MARK: Public
    
    private(set) var upgradingSubject: CurrentValueSubject<Bool, Never>
    private(set) var errorSubject: CurrentValueSubject<Error?, Never>
    private(set) var currentRoomId: String

    var parentSpaceName: String? {
        guard let parentId = self.parentSpaceId else {
            return nil
        }
        
        guard let parent = session.spaceService?.getSpace(withId: parentId) else {
            MXLog.error("[RoomUpgradeService] parentSpaceName: parent space not found.")
            return nil
        }
        
        return parent.room?.displayName
    }
    
    // MARK: - Setup
    
    init(session: MXSession, roomId: String, parentSpaceId: String?, versionOverride: String) {
        self.session = session
        self.currentRoomId = roomId
        self.parentSpaceId = parentSpaceId
        self.versionOverride = versionOverride
        self.upgradingSubject = CurrentValueSubject(false)
        self.errorSubject = CurrentValueSubject(nil)
    }

    deinit {
        currentOperation?.cancel()
        if let observer = self.didBuildSpaceGraphObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func upgradeRoom(autoInviteUsers: Bool, completion: @escaping (Bool, String) -> Void) {
        upgradingSubject.send(true)
        
        if autoInviteUsers, let room = session.room(withRoomId: self.currentRoomId) {
            self.currentOperation = room.members { [weak self] response in
                guard let self = self else { return }
                switch response {
                case .success(let members):
                    let memberIds: [String] = members?.members.compactMap({ member in
                        guard member.membership == .join, member.userId != self.session.myUserId else {
                            return nil
                        }

                        return member.userId
                    }) ?? []
                    self.upgradeRoom(to: self.versionOverride, inviteUsers: memberIds, completion: completion)
                case .failure(let error):
                    self.upgradingSubject.send(false)
                    self.errorSubject.send(error)
                }
            }
        } else {
            self.upgradeRoom(to: versionOverride, inviteUsers: [], completion: completion)
        }
    }
    
    // MARK: - Private
    
    private func upgradeRoom(to versionOverride: String, inviteUsers userIds: [String], completion: @escaping (Bool, String) -> Void) {
        // Need to disable graph update during this process as a lot of syncs will occure
        session.spaceService.graphUpdateEnabled = false
        currentOperation = session.matrixRestClient.upgradeRoom(withId: self.currentRoomId, to: versionOverride) { [weak self] response in
            guard let self = self else { return }
            
            switch response {
            case .success(let replacementRoomId):
                let oldRoomId = self.currentRoomId
                self.currentRoomId = replacementRoomId
                let parentSpaces = self.session.spaceService.directParentIds(ofRoomWithId: oldRoomId)
                self.moveRoom(from: oldRoomId, to: replacementRoomId, within: Array(parentSpaces), at: 0) {
                    self.session.spaceService.graphUpdateEnabled = true
                    self.didBuildSpaceGraphObserver = NotificationCenter.default.addObserver(forName: MXSpaceService.didBuildSpaceGraph, object: nil, queue: OperationQueue.main) { [weak self] notification in
                        guard let self = self else { return }
                        
                        if let observer = self.didBuildSpaceGraphObserver {
                            NotificationCenter.default.removeObserver(observer)
                            self.didBuildSpaceGraphObserver = nil
                        }
                        
                        DispatchQueue.main.async {
                            self.inviteUser(from: userIds, at: 0, completion: completion)
                        }
                    }
                }
            case .failure(let error):
                self.session.spaceService.graphUpdateEnabled = true
                self.upgradingSubject.send(false)
                self.errorSubject.send(error)
            }
        }
    }
    
    /// Move room with roomId to new room ID for each space which ID belongs to`parentIds` list.
    /// Recurse to the next index once done.
    private func moveRoom(from roomId: String, to newRoomId: String, within parentIds: [String], at index: Int, completion: @escaping () -> Void) {
        guard index < parentIds.count else {
            completion()
            return
        }
        
        guard let space = session.spaceService.getSpace(withId: parentIds[index]) else {
            MXLog.warning("[RoomUpgradeService] moveRoom \(roomId) to \(newRoomId) within \(parentIds[index]): space not found")
            moveRoom(from: roomId, to: newRoomId, within: parentIds, at: index + 1, completion: completion)
            return
        }
        
        space.moveChild(withRoomId: roomId, to: newRoomId) { [weak self] response in
            guard let self = self else  { return }
            
            if let error = response.error {
                MXLog.warning("[RoomUpgradeService] moveRoom \(roomId) to \(newRoomId) within \(space.spaceId): failed due to error: \(error)")
            }
            
            self.moveRoom(from: roomId, to: newRoomId, within: parentIds, at: index + 1, completion: completion)
        }
    }
    
    /// Invite all users within `userIds` list
    /// Recurse to the next index once done.
    private func inviteUser(from userIds: [String], at index: Int, completion: @escaping (Bool, String) -> Void) {
        guard index < userIds.count else {
            self.upgradingSubject.send(false)
            completion(true, currentRoomId)
            return
        }
        
        currentOperation = session.matrixRestClient.invite(.userId(userIds[index]), toRoom: currentRoomId) { [weak self] response in
            guard let self = self else  { return }
            
            self.currentOperation = nil
            if let error = response.error {
                MXLog.warning("[RoomUpgradeService] inviteUser: failed to invite \(userIds[index]) to \(self.currentRoomId) due to error: \(error)")
            }
            
            self.inviteUser(from: userIds, at: index + 1, completion: completion)
        }
    }
}
