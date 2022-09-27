// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationRooms SpaceCreationRooms
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
