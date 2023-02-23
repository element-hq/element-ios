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

import Combine
import Foundation
import MatrixSDK

class RoomAccessTypeChooserService: RoomAccessTypeChooserServiceProtocol {
    // MARK: - Properties

    // MARK: Private
    
    private let roomId: String
    private let allowsRoomUpgrade: Bool
    private let session: MXSession
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
    
    // MARK: Public
    
    private(set) var accessItemsSubject: CurrentValueSubject<[RoomAccessTypeChooserAccessItem], Never>
    private(set) var roomUpgradeRequiredSubject: CurrentValueSubject<Bool, Never>
    private(set) var waitingMessageSubject: CurrentValueSubject<String?, Never>
    private(set) var errorSubject: CurrentValueSubject<Error?, Never>

    private(set) var currentRoomId: String
    private(set) var versionOverride: String?

    // MARK: - Setup
    
    init(roomId: String, allowsRoomUpgrade: Bool, session: MXSession) {
        self.roomId = roomId
        self.allowsRoomUpgrade = allowsRoomUpgrade
        self.session = session
        currentRoomId = roomId
        versionOverride = session.homeserverCapabilitiesService.versionOverrideForFeature(.restricted)
        
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
    
    // MARK: - Public
    
    func updateSelection(with selectedType: RoomAccessTypeChooserAccessType) {
        self.selectedType = selectedType
        
        if selectedType == .restricted {
            if roomUpgradeRequired, roomUpgradeRequiredSubject.value == false {
                roomUpgradeRequiredSubject.send(true)
            }
        }
    }
    
    func applySelection(completion: @escaping () -> Void) {
        guard let room = session.room(withRoomId: currentRoomId) else {
            MXLog.error("[RoomAccessTypeChooserService] applySelection: room with ID not found", context: [
                "room_id": currentRoomId
            ])
            return
        }
        
        let _joinRule: MXRoomJoinRule?
        
        switch selectedType {
        case .private:
            _joinRule = .invite
        case .public:
            _joinRule = .public
        case .restricted:
            _joinRule = nil
            if roomUpgradeRequired, roomUpgradeRequiredSubject.value == false {
                roomUpgradeRequiredSubject.send(true)
            } else {
                completion()
            }
        }
        
        if let joinRule = _joinRule {
            waitingMessageSubject.send(VectorL10n.roomAccessSettingsScreenSettingRoomAccess)
            
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
    
    func updateRoomId(with roomId: String) {
        currentRoomId = roomId
        readRoomState()
    }
    
    // MARK: - Private
    
    private func setupAccessItems() {
        guard let spaceService = session.spaceService, let ancestors = spaceService.ancestorsPerRoomId[currentRoomId], !ancestors.isEmpty, allowsRoomUpgrade || !roomUpgradeRequired else {
            accessItems = [
                RoomAccessTypeChooserAccessItem(id: .private, isSelected: false, title: VectorL10n.private, detail: VectorL10n.roomAccessSettingsScreenPrivateMessage, badgeText: nil),
                RoomAccessTypeChooserAccessItem(id: .public, isSelected: false, title: VectorL10n.public, detail: VectorL10n.roomAccessSettingsScreenPublicMessage, badgeText: nil)
            ]
            return
        }

        accessItems = [
            RoomAccessTypeChooserAccessItem(id: .private, isSelected: false, title: VectorL10n.private, detail: VectorL10n.roomAccessSettingsScreenPrivateMessage, badgeText: nil),
            RoomAccessTypeChooserAccessItem(id: .restricted, isSelected: false, title: VectorL10n.createRoomTypeRestricted, detail: VectorL10n.roomAccessSettingsScreenRestrictedMessage, badgeText: roomUpgradeRequired ? VectorL10n.roomAccessSettingsScreenUpgradeRequired : VectorL10n.roomAccessSettingsScreenEditSpaces),
            RoomAccessTypeChooserAccessItem(id: .public, isSelected: false, title: VectorL10n.public, detail: VectorL10n.roomAccessSettingsScreenPublicMessage, badgeText: nil)
        ]
        
        accessItemsSubject.send(accessItems)
    }
    
    private func readRoomState() {
        guard let room = session.room(withRoomId: currentRoomId) else {
            MXLog.error("[RoomAccessTypeChooserService] readRoomState: room with ID not found", context: [
                "room_id": currentRoomId
            ])
            return
        }
        
        room.state { [weak self] state in
            guard let self = self else { return }
            
            if let roomVersion = state?.stateEvents(with: .roomCreate)?.last?.wireContent["room_version"] as? String, let homeserverCapabilitiesService = self.session.homeserverCapabilitiesService {
                self.roomUpgradeRequired = self.versionOverride != nil && !homeserverCapabilitiesService.isFeatureSupported(.restricted, by: roomVersion)
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
        
        if selectedType != .restricted {
            roomUpgradeRequiredSubject.send(false)
        }
    }
}
