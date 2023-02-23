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

class MockRoomAccessTypeChooserService: RoomAccessTypeChooserServiceProtocol {
    static let mockAccessItems: [RoomAccessTypeChooserAccessItem] = [
        RoomAccessTypeChooserAccessItem(id: .private, isSelected: true, title: VectorL10n.private, detail: VectorL10n.roomAccessSettingsScreenPrivateMessage, badgeText: nil),
        RoomAccessTypeChooserAccessItem(id: .restricted, isSelected: false, title: VectorL10n.createRoomTypeRestricted, detail: VectorL10n.roomAccessSettingsScreenRestrictedMessage, badgeText: VectorL10n.roomAccessSettingsScreenUpgradeRequired),
        RoomAccessTypeChooserAccessItem(id: .public, isSelected: false, title: VectorL10n.public, detail: VectorL10n.roomAccessSettingsScreenPublicMessage, badgeText: nil)
    ]
    
    private(set) var accessItemsSubject: CurrentValueSubject<[RoomAccessTypeChooserAccessItem], Never>
    private(set) var roomUpgradeRequiredSubject: CurrentValueSubject<Bool, Never>
    private(set) var waitingMessageSubject: CurrentValueSubject<String?, Never>
    private(set) var errorSubject: CurrentValueSubject<Error?, Never>

    private(set) var selectedType: RoomAccessTypeChooserAccessType = .private
    var currentRoomId = "!aaabaa:matrix.org"
    var versionOverride: String? {
        "9"
    }
    
    init(accessItems: [RoomAccessTypeChooserAccessItem] = mockAccessItems) {
        accessItemsSubject = CurrentValueSubject(accessItems)
        roomUpgradeRequiredSubject = CurrentValueSubject(false)
        waitingMessageSubject = CurrentValueSubject(nil)
        errorSubject = CurrentValueSubject(nil)
    }
    
    func simulateUpdate(accessItems: [RoomAccessTypeChooserAccessItem]) {
        accessItemsSubject.send(accessItems)
    }
    
    func updateSelection(with selectedType: RoomAccessTypeChooserAccessType) { }
    
    func updateRoomId(with roomId: String) {
        currentRoomId = roomId
    }
    
    func applySelection(completion: @escaping () -> Void) { }
}
