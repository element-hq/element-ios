// 
// Copyright 2020 New Vector Ltd
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

/// `RoomService` errors
enum RoomServiceError: Error {
    case roomNotFound
    case roomAlreadyJoined
    case cannotJoinRoom
    case roomAlreadyLeft
    case cannotLeaveRoom
    case changeMembershipAlreadyInProgress
}

/// `RoomService` enables to manage room
@objcMembers
class RoomService: NSObject, RoomServiceProtocol {
    
    // MARK: - Constants
    
    // NOTE: Use shared instance as we can't inject easily this dependency at the moment. Remove when injection will be possible.
    static let shared = RoomService()
    
    // MARK: - Properties
    
    private var session: MXSession!
    private let roomChangeMembershipStateDataSource: RoomChangeMembershipStateDataSource
    private var roomChangeMembershipOperations: [String: MXHTTPOperation] = [:]
    
    // MARK: - Setup
    
    override init() {
        self.roomChangeMembershipStateDataSource = RoomChangeMembershipStateDataSource()
        super.init()
    }
    
    // MARK: - Public
    
    // TODO: To remove once session will be injected in constructor
    func updateSession(_ session: MXSession) {
        guard session != self.session else {
            return
        }
        self.session = session
        
        self.roomChangeMembershipOperations = [:]
    }
    
    @discardableResult
    func join(roomWithId roomId: String, success: @escaping (() -> Void), failure: @escaping ((Error) -> Void)) -> MXHTTPOperation? {
        guard let room = self.session.room(withRoomId: roomId) else {
            failure(RoomServiceError.roomNotFound)
            return nil
        }
        
        let changeMembershipState = self.roomChangeMembershipStateDataSource.createOrUpdateStateIfNeeded(for: roomId, and: room.summary.membership)
        
        if case .failure(let error) = self.canJoinRoom(for: changeMembershipState) {
            failure(error)
            return nil
        }
        
        guard self.isPendingRoomChangeMembershipOperationExists(for: roomId) == false else {
            failure(RoomServiceError.changeMembershipAlreadyInProgress)
            return nil
        }
                
        let httpOperation = room.join { response in
            switch response {
            case .success:
                self.roomChangeMembershipStateDataSource.updateState(for: roomId, with: .joined)
                self.removeRoomChangeMembershipOperation(for: roomId)
                success()
            case .failure(let error):
                self.roomChangeMembershipStateDataSource.updateState(for: roomId, with: .failedJoining(error))
                self.removeRoomChangeMembershipOperation(for: roomId)
                failure(error)
            }
        }
        
        self.addChangeMembershipTask(for: roomId, changeMembershipState: .joining, httpOperation: httpOperation)
        
        return httpOperation
    }
    
    @discardableResult
    func leave(roomWithId roomId: String, success: @escaping (() -> Void), failure: @escaping ((Error) -> Void)) -> MXHTTPOperation? {
        guard let room = self.session.room(withRoomId: roomId) else {
            failure(RoomServiceError.roomNotFound)
            return nil
        }
        
        let changeMembershipState = self.roomChangeMembershipStateDataSource.createOrUpdateStateIfNeeded(for: roomId, and: room.summary.membership)
        
        if case .failure(let error) = self.canLeaveRoom(for: changeMembershipState) {
            failure(error)
            return nil
        }
        
        guard self.isPendingRoomChangeMembershipOperationExists(for: roomId) == false else {
            failure(RoomServiceError.changeMembershipAlreadyInProgress)
            return nil
        }
                
        let httpOperation = room.leave { response in
            switch response {
            case .success:
                self.roomChangeMembershipStateDataSource.updateState(for: roomId, with: .left)
                self.removeRoomChangeMembershipOperation(for: roomId)
                success()
            case .failure(let error):
                self.roomChangeMembershipStateDataSource.updateState(for: roomId, with: .failedLeaving(error))
                self.removeRoomChangeMembershipOperation(for: roomId)
                failure(error)
            }
        }
        
        self.addChangeMembershipTask(for: roomId, changeMembershipState: .leaving, httpOperation: httpOperation)
        
        return httpOperation
    }
        
    /// Get the current `ChangeMembershipState` for the room
    /// - Parameter roomId: The room id
    func getChangeMembeshipState(for roomId: String) -> ChangeMembershipState {
        return self.roomChangeMembershipStateDataSource.getState(for: roomId) ?? .unknown
    }
    
    // MARK: - Private
    
    // MARK: Membership change
    
    private func isPendingRoomChangeMembershipOperationExists(for roomId: String) -> Bool {
        return self.roomChangeMembershipOperations[roomId] != nil
    }
    
    private func canJoinRoom(for changeMembershipState: ChangeMembershipState) -> Result<Void, Error> {
        let result: Result<Void, Error>
        
        switch changeMembershipState {
        case .joining, .leaving:
            result = .failure(RoomServiceError.changeMembershipAlreadyInProgress)
        case .joined:
            result = .failure(RoomServiceError.roomAlreadyJoined)
        default:
            result = .success(Void())
        }                
            
        return result
    }
    
    private func canLeaveRoom(for changeMembershipState: ChangeMembershipState) -> Result<Void, Error> {
        let result: Result<Void, Error>
        
        switch changeMembershipState {
        case .joining, .leaving:
            result = .failure(RoomServiceError.changeMembershipAlreadyInProgress)
        case .left:
            result = .failure(RoomServiceError.roomAlreadyLeft)
        default:
            result = .success(Void())
        }
            
        return result
    }
    
    private func addChangeMembershipTask(for roomId: String,
                                         changeMembershipState: ChangeMembershipState,
                                         httpOperation: MXHTTPOperation) {
        self.roomChangeMembershipStateDataSource.updateState(for: roomId, with: changeMembershipState)
        self.roomChangeMembershipOperations[roomId] = httpOperation
    }
    
    private func removeRoomChangeMembershipOperation(for roomId: String) {
        self.roomChangeMembershipOperations[roomId] = nil
    }
}
