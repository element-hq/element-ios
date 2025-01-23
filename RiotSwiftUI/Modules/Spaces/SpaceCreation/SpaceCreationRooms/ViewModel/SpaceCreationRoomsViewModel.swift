// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationRooms SpaceCreationRooms
//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias SpaceCreationRoomsViewModelType = StateStoreViewModel<SpaceCreationRoomsViewState, SpaceCreationRoomsViewAction>

class SpaceCreationRoomsViewModel: SpaceCreationRoomsViewModelType, SpaceCreationRoomsViewModelProtocol {
    // MARK: - Setup
    
    // MARK: Private

    private let creationParameters: SpaceCreationParameters
    
    // MARK: Public

    var callback: ((SpaceCreationRoomsViewModelResult) -> Void)?

    // MARK: - Setup
    
    init(creationParameters: SpaceCreationParameters) {
        self.creationParameters = creationParameters
        super.init(initialViewState: SpaceCreationRoomsViewModel.defaultState(creationParameters: creationParameters))
    }
    
    private static func defaultState(creationParameters: SpaceCreationParameters) -> SpaceCreationRoomsViewState {
        let bindings = SpaceCreationRoomsViewModelBindings(rooms: creationParameters.newRooms)
        return SpaceCreationRoomsViewState(
            title: creationParameters.isPublic ? VectorL10n.spacesCreationPublicSpaceTitle : VectorL10n.spacesCreationPrivateSpaceTitle,
            bindings: bindings
        )
    }

    // MARK: - Public

    override func process(viewAction: SpaceCreationRoomsViewAction) {
        switch viewAction {
        case .cancel:
            cancel()
        case .back:
            back()
        case .done:
            done()
        }
    }
    
    // MARK: - Private

    private func done() {
        creationParameters.newRooms = context.rooms
        callback?(.done)
    }

    private func back() {
        callback?(.back)
    }

    private func cancel() {
        callback?(.cancel)
    }
}
