//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

/// Using an enum for the screen allows you define the different state cases with
/// the relevant associated data for each case.
enum MockRoomAccessTypeChooserScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case noSelection
    case selection
    
    /// The associated screen
    var screenType: Any.Type {
        RoomAccessTypeChooser.self
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let service: MockRoomAccessTypeChooserService
        switch self {
        case .noSelection:
            service = MockRoomAccessTypeChooserService()
        case .selection:
            service = MockRoomAccessTypeChooserService(accessItems: [
                RoomAccessTypeChooserAccessItem(id: .private, isSelected: true, title: VectorL10n.private, detail: VectorL10n.roomAccessSettingsScreenPrivateMessage, badgeText: nil),
                RoomAccessTypeChooserAccessItem(id: .restricted, isSelected: false, title: VectorL10n.createRoomTypeRestricted, detail: VectorL10n.roomAccessSettingsScreenRestrictedMessage, badgeText: VectorL10n.roomAccessSettingsScreenUpgradeRequired),
                RoomAccessTypeChooserAccessItem(id: .public, isSelected: false, title: VectorL10n.public, detail: VectorL10n.roomAccessSettingsScreenPublicMessage, badgeText: nil)
            ])
        }
        let viewModel = RoomAccessTypeChooserViewModel(roomAccessTypeChooserService: service)
        
        // can simulate service and viewModel actions here if needs be.
        
        return (
            [service, viewModel],
            AnyView(RoomAccessTypeChooser(viewModel: viewModel.context, roomName: "Room Name")
                .environmentObject(AvatarViewModel.withMockedServices()))
        )
    }
}
