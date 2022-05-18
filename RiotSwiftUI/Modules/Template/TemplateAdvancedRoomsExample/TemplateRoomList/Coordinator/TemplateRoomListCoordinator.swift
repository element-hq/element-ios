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

struct TemplateRoomListCoordinatorParameters {
    let session: MXSession
}

final class TemplateRoomListCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: TemplateRoomListCoordinatorParameters
    private let templateRoomListHostingController: UIViewController
    private var templateRoomListViewModel: TemplateRoomListViewModelProtocol
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: ((TemplateRoomListCoordinatorAction) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: TemplateRoomListCoordinatorParameters) {
        self.parameters = parameters
        let viewModel = TemplateRoomListViewModel(templateRoomListService: TemplateRoomListService(session: parameters.session))
        let view = TemplateRoomList(viewModel: viewModel.context)
            .addDependency(AvatarService.instantiate(mediaManager: parameters.session.mediaManager))
        templateRoomListViewModel = viewModel
        templateRoomListHostingController = VectorHostingController(rootView: view)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[TemplateRoomListCoordinator] did start.")
        templateRoomListViewModel.callback = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[TemplateRoomListCoordinator] TemplateRoomListViewModel did complete with result \(result).")
            switch result {
            case .didSelectRoom(let roomId):
                self.callback?(.didSelectRoom(roomId))
            case .done:
                self.callback?(.done)
            break
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.templateRoomListHostingController
    }
}
