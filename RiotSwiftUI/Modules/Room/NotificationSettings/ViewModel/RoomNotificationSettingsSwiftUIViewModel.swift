//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

class RoomNotificationSettingsSwiftUIViewModel: RoomNotificationSettingsViewModel, ObservableObject {
    @Published var viewState: RoomNotificationSettingsViewState
    
    lazy var cancellables = Set<AnyCancellable>()
    
    override init(roomNotificationService: RoomNotificationSettingsServiceType, initialState: RoomNotificationSettingsViewState) {
        viewState = initialState
        super.init(roomNotificationService: roomNotificationService, initialState: initialState)
    }
    
    override func update(viewState: RoomNotificationSettingsViewState) {
        super.update(viewState: viewState)
        self.viewState = viewState
    }
}
