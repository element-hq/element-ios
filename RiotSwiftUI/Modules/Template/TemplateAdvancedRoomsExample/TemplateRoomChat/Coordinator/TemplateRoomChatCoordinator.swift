//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct TemplateRoomChatCoordinatorParameters {
    let room: MXRoom
}

final class TemplateRoomChatCoordinator: Coordinator, Presentable {
    private let parameters: TemplateRoomChatCoordinatorParameters
    private let templateRoomChatHostingController: UIViewController
    private var templateRoomChatViewModel: TemplateRoomChatViewModelProtocol

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: (() -> Void)?
    
    init(parameters: TemplateRoomChatCoordinatorParameters) {
        self.parameters = parameters
        let viewModel = TemplateRoomChatViewModel(templateRoomChatService: TemplateRoomChatService(room: parameters.room))
        let view = TemplateRoomChat(viewModel: viewModel.context)
            .environmentObject(AvatarViewModel(avatarService: AvatarService(mediaManager: parameters.room.mxSession.mediaManager)))

        templateRoomChatViewModel = viewModel
        templateRoomChatHostingController = VectorHostingController(rootView: view)
    }
    
    // MARK: - Public

    func start() {
        MXLog.debug("[TemplateRoomChatCoordinator] did start.")
        templateRoomChatViewModel.callback = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[TemplateRoomChatCoordinator] TemplateRoomChatViewModel did complete with result: \(result).")
            switch result {
            case .done:
                self.callback?()
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        templateRoomChatHostingController
    }
}
