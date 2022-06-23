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
import MatrixSDK

struct RoomUpgradeCoordinatorParameters {
    let session: MXSession
    let roomId: String
    let parentSpaceId: String?
    let versionOverride: String
}

final class RoomUpgradeCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: RoomUpgradeCoordinatorParameters
    private let roomUpgradeHostingController: UIViewController
    private var roomUpgradeViewModel: RoomUpgradeViewModelProtocol
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((RoomUpgradeCoordinatorResult) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: RoomUpgradeCoordinatorParameters) {
        self.parameters = parameters
        let viewModel = RoomUpgradeViewModel.makeRoomUpgradeViewModel(roomUpgradeService: RoomUpgradeService(session: parameters.session, roomId: parameters.roomId, parentSpaceId: parameters.parentSpaceId, versionOverride: parameters.versionOverride))
        let view = RoomUpgrade(viewModel: viewModel.context)
            .addDependency(AvatarService.instantiate(mediaManager: parameters.session.mediaManager))
        roomUpgradeViewModel = viewModel
        roomUpgradeHostingController = VectorHostingController(rootView: view)
        roomUpgradeHostingController.view.backgroundColor = .clear
    }
    
    // MARK: - Public
    func start() {
        MXLog.debug("[RoomUpgradeCoordinator] did start.")
        roomUpgradeViewModel.completion = { [weak self] result in
            MXLog.debug("[RoomUpgradeCoordinator] RoomUpgradeViewModel did complete with result: \(result).")
            guard let self = self else { return }
            switch result {
            case .cancel(let roomId):
                self.completion?(.cancel(roomId))
            case .done(let roomId):
                self.completion?(.done(roomId))
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.roomUpgradeHostingController
    }
}
