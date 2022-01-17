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

@available(iOS 14.0, *)
class RoomAccessTypeChooserService: RoomAccessTypeChooserServiceProtocol {
    
    // MARK: - Properties

    // MARK: Private
    
    private let roomId: String
    private let session:MXSession
    private var replacementRoom: MXRoom?
    private var didBuildSpaceGraphObserver: Any?
    private var accessItems: [RoomAccessTypeChooserAccessItem] = []
    private var roomUpgradeRequired = false {
        didSet {
            for (index, item) in accessItems.enumerated() {
                if item.id == .restricted {
                    accessItems[index].badgeText = roomUpgradeRequired ? VectorL10n.roomAccessSettingsScreenUpgradeRequired : VectorL10n.roomAccessSettingsScreenEditSpaces
                }
            }
            accessItemsSubject.send(accessItems)
        }
    }
    private(set) var selectedType: RoomAccessTypeChooserAccessType = .private {
        didSet {
            for (index, item) in accessItems.enumerated() {
                accessItems[index].isSelected = selectedType == item.id
            }
            accessItemsSubject.send(accessItems)
        }
    }
    private var roomJoinRule: MXRoomJoinRule = .private
    private var currentOperation: MXHTTPOperation?
    private let restrictedVersionOverride: String?
    
    // MARK: Public
    
    private(set) var accessItemsSubject: CurrentValueSubject<[RoomAccessTypeChooserAccessItem], Never>
    private(set) var roomUpgradeRequiredSubject: CurrentValueSubject<Bool, Never>
    private(set) var waitingMessageSubject: CurrentValueSubject<String?, Never>
    private(set) var errorSubject: CurrentValueSubject<Error?, Never>

    private(set) var currentRoomId: String

    // MARK: - Setup
    
    init(roomId: String, session: MXSession) {
        self.roomId = roomId
        self.session = session
        self.currentRoomId = roomId
        restrictedVersionOverride = session.homeserverCapabilities.versionOverrideForFeature(.restricted)
        
        roomUpgradeRequiredSubject = CurrentValueSubject(false)
        waitingMessageSubject = CurrentValueSubject(nil)
        accessItemsSubject = CurrentValueSubject(accessItems)
        errorSubject = CurrentValueSubject(nil)
        
        setupAccessItems()
        readRoomState()
    }
    
    deinit {
        currentOperation?.cancel()
        if let observer = self.didBuildSpaceGraphObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func updateSelection(with selectedType: RoomAccessTypeChooserAccessType) {
        self.selectedType = selectedType
        
        if selectedType == .restricted {
            if roomUpgradeRequired && roomUpgradeRequiredSubject.value == false {
                roomUpgradeRequiredSubject.send(true)
            }
        }
    }
    
    func applySelection(completion: @escaping () -> Void) {
        guard let room = session.room(withRoomId: currentRoomId) else {
            fatalError("[RoomAccessTypeChooserService] applySelection: room with ID \(currentRoomId) not found")
        }
        
        let _joinRule: MXRoomJoinRule?
        
        switch self.selectedType {
        case .private:
            _joinRule = .private
        case .public:
            _joinRule = .public
        case .restricted:
            _joinRule = nil
            if roomUpgradeRequired && roomUpgradeRequiredSubject.value == false {
                roomUpgradeRequiredSubject.send(true)
            } else {
                completion()
            }
        }
        
        if let joinRule = _joinRule {
            
//            waitingMessageSubject.send(VectorL10n.roomAccessSettingsScreenSettingRoomAccess)
//            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                self.waitingMessageSubject.send(nil)
//                completion()
//            }
            room.setJoinRule(joinRule) { [weak self] response in
                guard let self = self else { return }

                self.waitingMessageSubject.send(nil)
                switch response {
                case .failure(let error):
                    self.errorSubject.send(error)
                case .success:
                    completion()
                }
            }
        }
    }
    
    func upgradeRoom(accepted: Bool, autoInviteUsers: Bool, completion: @escaping (Bool, String) -> Void) {
        roomUpgradeRequiredSubject.send(false)

        guard let restrictedVersionOverride = restrictedVersionOverride, accepted else {
            setupDefaultSelectionType()
            completion(false, currentRoomId)
            return
        }
        
        waitingMessageSubject.send(VectorL10n.roomAccessSettingsScreenUpgradeAlertUpgrading)
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//            self.waitingMessageSubject.send(nil)
//            self.roomUpgradeRequired = false
//            completion(true, self.currentRoomId)
//        }

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
                    self.upgradeRoom(to: restrictedVersionOverride, inviteUsers: memberIds, completion: completion)
                case .failure(let error):
                    self.waitingMessageSubject.send(nil)
                    self.errorSubject.send(error)
                }
            }
        } else {
            self.upgradeRoom(to: restrictedVersionOverride, inviteUsers: [], completion: completion)
        }
    }
    
    // MARK: - Private
    
    private func setupAccessItems() {
        guard let spaceService = session.spaceService, let ancestors = spaceService.ancestorsPerRoomId[currentRoomId], !ancestors.isEmpty else {
            self.accessItems = [
                RoomAccessTypeChooserAccessItem(id: .private, isSelected: false, title: VectorL10n.private, detail: VectorL10n.roomAccessSettingsScreenPrivateMessage, badgeText: nil),
                RoomAccessTypeChooserAccessItem(id: .public, isSelected: false, title: VectorL10n.public, detail: VectorL10n.roomAccessSettingsScreenPublicMessage, badgeText: nil),
            ]
            return
        }

        self.accessItems = [
            RoomAccessTypeChooserAccessItem(id: .private, isSelected: false, title: VectorL10n.private, detail: VectorL10n.roomAccessSettingsScreenPrivateMessage, badgeText: nil),
            RoomAccessTypeChooserAccessItem(id: .restricted, isSelected: false, title: VectorL10n.createRoomTypeRestricted, detail: VectorL10n.roomAccessSettingsScreenRestrictedMessage, badgeText: roomUpgradeRequired ? VectorL10n.roomAccessSettingsScreenUpgradeRequired : VectorL10n.roomAccessSettingsScreenEditSpaces),
            RoomAccessTypeChooserAccessItem(id: .public, isSelected: false, title: VectorL10n.public, detail: VectorL10n.roomAccessSettingsScreenPublicMessage, badgeText: nil),
        ]
        
        accessItemsSubject.send(accessItems)
    }
    
    private func readRoomState() {
        guard let room = session.room(withRoomId: currentRoomId) else {
            fatalError("[RoomAccessTypeChooserService] readRoomState: room with ID \(currentRoomId) not found")
        }
        
        room.state { [weak self] state in
            guard let self = self else { return }
            
            if let roomVersion = state?.stateEvents(with: .roomCreate)?.last?.wireContent["room_version"] as? String, let homeserverCapabilitiesService = self.session.homeserverCapabilities {
                self.roomUpgradeRequired = self.restrictedVersionOverride != nil && !homeserverCapabilitiesService.isFeatureSupported(.restricted, by: roomVersion)
            }
            
            self.roomJoinRule = state?.joinRule ?? .private
            self.setupDefaultSelectionType()
        }
    }

    private func setupDefaultSelectionType() {
        switch roomJoinRule {
        case .restricted:
            selectedType = .restricted
        case .public:
            selectedType = .public
        default:
            selectedType = .private
        }
    }
    
    private func upgradeRoom(to restrictedVersionOverride: String, inviteUsers userIds: [String], completion: @escaping (Bool, String) -> Void) {
        // Need to disable graph update during this process as a lot of syncs will occure
        session.spaceService.graphUpdateEnabled = false
        currentOperation = session.matrixRestClient.upgradeRoom(withId: self.currentRoomId, to: restrictedVersionOverride) { [weak self] response in
            guard let self = self else { return }
            
            switch response {
            case .success(let replacementRoomId):
                let oldRoomId = self.currentRoomId
                self.roomUpgradeRequired = false
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
                self.waitingMessageSubject.send(nil)
                self.errorSubject.send(error)
            }
        }
    }
    
    private func moveRoom(from roomId: String, to newRoomId: String, within parentIds: [String], at index: Int, completion: @escaping () -> Void) {
        guard index < parentIds.count else {
            completion()
            return
        }
        
        guard let space = session.spaceService.getSpace(withId: parentIds[index]) else {
            MXLog.warning("[RoomAccessTypeChooserService] moveRoom \(roomId) to \(newRoomId) within \(parentIds[index]): space not found")
            moveRoom(from: roomId, to: newRoomId, within: parentIds, at: index + 1, completion: completion)
            return
        }
        
        space.moveChild(withRoomId: roomId, to: newRoomId) { [weak self] response in
            guard let self = self else  { return }
            
            if let error = response.error {
                MXLog.warning("[RoomAccessTypeChooserService] moveRoom \(roomId) to \(newRoomId) within \(space.spaceId): failed due to error: \(error)")
            }
            
            self.moveRoom(from: roomId, to: newRoomId, within: parentIds, at: index + 1, completion: completion)
        }
    }
    
    private func inviteUser(from userIds: [String], at index: Int, completion: @escaping (Bool, String) -> Void) {
        guard index < userIds.count else {
            self.waitingMessageSubject.send(nil)
            completion(true, currentRoomId)
            return
        }
        
        currentOperation = session.matrixRestClient.invite(.userId(userIds[index]), toRoom: currentRoomId) { [weak self] response in
            guard let self = self else  { return }
            
            self.currentOperation = nil
            if let error = response.error {
                MXLog.warning("[RoomAccessTypeChooserService] inviteUser: failed to invite \(userIds[index]) to \(self.currentRoomId) due to error: \(error)")
            }
            
            self.inviteUser(from: userIds, at: index + 1, completion: completion)
        }
    }
}
