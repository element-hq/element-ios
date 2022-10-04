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

import SwiftUI

struct RoomAccessTypeChooserCoordinatorParameters {
    let roomId: String
    let allowsRoomUpgrade: Bool
    let session: MXSession
}

final class RoomAccessTypeChooserCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: RoomAccessTypeChooserCoordinatorParameters
    private let roomAccessTypeChooserHostingController: UIViewController
    private var roomAccessTypeChooserViewModel: RoomAccessTypeChooserViewModelProtocol
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: ((RoomAccessTypeChooserCoordinatorAction) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: RoomAccessTypeChooserCoordinatorParameters) {
        self.parameters = parameters
        let viewModel = RoomAccessTypeChooserViewModel(roomAccessTypeChooserService: RoomAccessTypeChooserService(roomId: parameters.roomId, allowsRoomUpgrade: parameters.allowsRoomUpgrade, session: parameters.session))
        let room = parameters.session.room(withRoomId: parameters.roomId)
        let view = RoomAccessTypeChooser(viewModel: viewModel.context, roomName: room?.displayName ?? "")
        roomAccessTypeChooserViewModel = viewModel
        roomAccessTypeChooserHostingController = VectorHostingController(rootView: view)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[RoomAccessTypeChooserCoordinator] did start.")
        roomAccessTypeChooserViewModel.callback = { [weak self] result in
            MXLog.debug("[RoomAccessTypeChooserCoordinator] RoomAccessTypeChooserViewModel did complete with result \(result).")
            guard let self = self else { return }
            switch result {
            case .spaceSelection(let roomId, let accessType):
                self.callback?(.spaceSelection(roomId, accessType))
            case .done(let roomId):
                self.callback?(.done(roomId))
            case .cancel(let roomId):
                self.callback?(.cancel(roomId))
            case .roomUpgradeNeeded(let roomId, let versionOverride):
                self.callback?(.roomUpgradeNeeded(roomId, versionOverride))
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        roomAccessTypeChooserHostingController
    }
    
    func handleRoomUpgradeResult(_ result: RoomUpgradeCoordinatorResult) {
        roomAccessTypeChooserViewModel.handleRoomUpgradeResult(result)
    }
}
