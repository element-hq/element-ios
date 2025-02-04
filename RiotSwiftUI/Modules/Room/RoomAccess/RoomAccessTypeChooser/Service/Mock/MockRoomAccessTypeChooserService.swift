//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
