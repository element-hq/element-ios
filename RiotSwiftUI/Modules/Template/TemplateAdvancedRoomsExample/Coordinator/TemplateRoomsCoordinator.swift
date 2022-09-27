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

import UIKit

@objcMembers
final class TemplateRoomsCoordinator: Coordinator, Presentable {
    private let parameters: TemplateRoomsCoordinatorParameters
    
    private var navigationRouter: NavigationRouterType {
        parameters.navigationRouter
    }
    
    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    var callback: (() -> Void)?
    
    init(parameters: TemplateRoomsCoordinatorParameters) {
        self.parameters = parameters
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[TemplateRoomsCoordinator] did start.")
        let rootCoordinator = createTemplateRoomListCoordinator()
        rootCoordinator.start()
        
        add(childCoordinator: rootCoordinator)
        
        if navigationRouter.modules.isEmpty == false {
            navigationRouter.push(rootCoordinator, animated: true, popCompletion: { [weak self] in
                self?.remove(childCoordinator: rootCoordinator)
            })
        } else {
            navigationRouter.setRootModule(rootCoordinator) { [weak self] in
                self?.remove(childCoordinator: rootCoordinator)
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        navigationRouter.toPresentable()
    }
    
    // MARK: - Private
    
    private func createTemplateRoomListCoordinator() -> TemplateRoomListCoordinator {
        let coordinator = TemplateRoomListCoordinator(parameters: TemplateRoomListCoordinatorParameters(session: parameters.session))
        
        coordinator.callback = { [weak self] result in
            MXLog.debug("[TemplateRoomsCoordinator] TemplateRoomListCoordinator did complete with result \(result).")
            guard let self = self else { return }
            switch result {
            case .didSelectRoom(let roomId):
                self.showTemplateRoomChat(roomId: roomId)
            case .done:
                self.callback?()
            }
        }
        return coordinator
    }
    
    private func createTemplateRoomChatCoordinator(room: MXRoom) -> TemplateRoomChatCoordinator {
        let coordinator = TemplateRoomChatCoordinator(parameters: TemplateRoomChatCoordinatorParameters(room: room))
        return coordinator
    }
    
    func showTemplateRoomChat(roomId: String) {
        guard let room = parameters.session.room(withRoomId: roomId) else {
            MXLog.error("[TemplateRoomsCoordinator] Failed to find room by selected Id.")
            return
        }
        let templateRoomChatCoordinator = createTemplateRoomChatCoordinator(room: room)
        
        add(childCoordinator: templateRoomChatCoordinator)
        
        navigationRouter.push(templateRoomChatCoordinator, animated: true, popCompletion: { [weak self] in
            self?.remove(childCoordinator: templateRoomChatCoordinator)
        })
        
        templateRoomChatCoordinator.start()
    }
}
