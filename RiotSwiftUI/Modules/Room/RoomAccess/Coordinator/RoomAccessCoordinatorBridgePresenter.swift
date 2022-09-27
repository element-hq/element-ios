//
import MatrixSDK
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

@objc protocol RoomAccessCoordinatorBridgePresenterDelegate {
    func roomAccessCoordinatorBridgePresenterDelegate(_ coordinatorBridgePresenter: RoomAccessCoordinatorBridgePresenter, didCancelRoomWithId roomId: String)
    func roomAccessCoordinatorBridgePresenterDelegate(_ coordinatorBridgePresenter: RoomAccessCoordinatorBridgePresenter, didCompleteRoomWithId roomId: String)
}

/// RoomNotificationSettingsCoordinatorBridgePresenter enables to start RoomNotificationSettingsCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
/// It breaks the Coordinator abstraction and it has been introduced for Objective-C compatibility (mainly for integration in legacy view controllers).
/// Each bridge should be removed once the underlying Coordinator has been integrated by another Coordinator.
@objcMembers
final class RoomAccessCoordinatorBridgePresenter: NSObject {
    // MARK: - Properties
    
    // MARK: Private
    
    private let room: MXRoom
    private let parentSpaceId: String?
    private let allowsRoomUpgrade: Bool
    private var coordinator: RoomAccessCoordinator?
    
    // MARK: Public
    
    weak var delegate: RoomAccessCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(room: MXRoom,
         parentSpaceId: String?,
         allowsRoomUpgrade: Bool) {
        self.room = room
        self.parentSpaceId = parentSpaceId
        self.allowsRoomUpgrade = allowsRoomUpgrade
        super.init()
    }
    
    convenience init(room: MXRoom,
                     parentSpaceId: String?) {
        self.init(room: room, parentSpaceId: parentSpaceId, allowsRoomUpgrade: true)
    }
    
    // MARK: - Public
    
    func present(from viewController: UIViewController, animated: Bool) {
        let navigationRouter = NavigationRouter()
        let coordinator = RoomAccessCoordinator(parameters: RoomAccessCoordinatorParameters(room: room, parentSpaceId: parentSpaceId, allowsRoomUpgrade: allowsRoomUpgrade, navigationRouter: navigationRouter))
        coordinator.callback = { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .cancel(let roomId):
                self.delegate?.roomAccessCoordinatorBridgePresenterDelegate(self, didCancelRoomWithId: roomId)
            case .done(let roomId):
                self.delegate?.roomAccessCoordinatorBridgePresenterDelegate(self, didCompleteRoomWithId: roomId)
            }
        }
        let presentable = coordinator.toPresentable()
        presentable.presentationController?.delegate = self
        navigationRouter.setRootModule(presentable)
        viewController.present(navigationRouter.toPresentable(), animated: animated, completion: nil)
        coordinator.start()
        
        self.coordinator = coordinator
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let coordinator = coordinator else {
            return
        }
        coordinator.toPresentable().dismiss(animated: animated) {
            self.coordinator = nil

            if let completion = completion {
                completion()
            }
        }
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension RoomAccessCoordinatorBridgePresenter: UIAdaptivePresentationControllerDelegate {
    func roomNotificationSettingsCoordinatorDidComplete(_ presentationController: UIPresentationController) {
        if let roomId = coordinator?.currentRoomId {
            delegate?.roomAccessCoordinatorBridgePresenterDelegate(self, didCancelRoomWithId: roomId)
        } else {
            delegate?.roomAccessCoordinatorBridgePresenterDelegate(self, didCancelRoomWithId: room.roomId)
        }
    }
}
