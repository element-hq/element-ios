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
import Foundation

@objc protocol RoomCoordinatorBridgePresenterDelegate {
    func roomCoordinatorBridgePresenterDidLeaveRoom(_ bridgePresenter: RoomCoordinatorBridgePresenter)
    func roomCoordinatorBridgePresenterDidCancelRoomPreview(_ bridgePresenter: RoomCoordinatorBridgePresenter)
    func roomCoordinatorBridgePresenter(_ bridgePresenter: RoomCoordinatorBridgePresenter, didSelectRoomWithId roomId: String)
    func roomCoordinatorBridgePresenterDidDismissInteractively(_ bridgePresenter: RoomCoordinatorBridgePresenter)
}

@objcMembers
class RoomCoordinatorBridgePresenterParameters: NSObject {
        
    /// The matrix session in which the room should be available.
    let session: MXSession
    
    /// The room identifier
    let roomId: String
    
    /// If not nil, the room will be opened on this event.
    let eventId: String?
    
    /// The data for the room preview.
    let previewData: RoomPreviewData?
    
    init(session: MXSession,
         roomId: String,
         eventId: String?,
         previewData: RoomPreviewData?) {
        self.session = session
        self.roomId = roomId
        self.eventId = eventId
        self.previewData = previewData
    }
}

/// RoomCoordinatorBridgePresenter enables to start RoomCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
/// **WARNING**: This class breaks the Coordinator abstraction and it has been introduced for **Objective-C compatibility only** (mainly for integration in legacy view controllers). Each bridge should be removed once the underlying Coordinator has been integrated by another Coordinator.
@objcMembers
final class RoomCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
        
    private let bridgeParameters: RoomCoordinatorBridgePresenterParameters
    private var coordinator: RoomCoordinator?
    
    // MARK: Public
    
    weak var delegate: RoomCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(parameters: RoomCoordinatorBridgePresenterParameters) {
        self.bridgeParameters = parameters
        super.init()
    }
    
    // MARK: - Public
    
    func present(from viewController: UIViewController, animated: Bool) {
        
        let coordinator = self.createRoomCoordinator()
        coordinator.delegate = self
        let presentable = coordinator.toPresentable()
        presentable.modalPresentationStyle = .formSheet
        viewController.present(presentable, animated: animated, completion: nil)
        coordinator.start()
        
        self.coordinator = coordinator
    }
    
    func push(from navigationController: UINavigationController, animated: Bool) {
        
        let navigationRouter = NavigationRouterStore.shared.navigationRouter(for: navigationController)
        
        let coordinator = self.createRoomCoordinator(with: navigationRouter)
        coordinator.delegate = self
        coordinator.start() // Will trigger view controller push
        
        self.coordinator = coordinator
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let coordinator = self.coordinator else {
            return
        }
        coordinator.toPresentable().dismiss(animated: animated) {
            self.coordinator = nil

            completion?()
        }
    }
    
    // MARK: - Private
    
    private func createRoomCoordinator(with navigationRouter: NavigationRouterType = NavigationRouter(navigationController: RiotNavigationController())) -> RoomCoordinator {
        
        let coordinatorParameters: RoomCoordinatorParameters
        
        if let previewData = self.bridgeParameters.previewData {
            coordinatorParameters = RoomCoordinatorParameters(navigationRouter: navigationRouter, previewData: previewData)
        } else {
            coordinatorParameters =  RoomCoordinatorParameters(navigationRouter: navigationRouter, session: self.bridgeParameters.session, roomId: self.bridgeParameters.roomId, eventId: self.bridgeParameters.eventId)
        }
        
        return RoomCoordinator(parameters: coordinatorParameters)
    }
}

// MARK: - RoomNotificationSettingsCoordinatorDelegate
extension RoomCoordinatorBridgePresenter: RoomCoordinatorDelegate {
    
    func roomCoordinator(_ coordinator: RoomCoordinatorProtocol, didSelectRoomWithId roomId: String) {
        self.delegate?.roomCoordinatorBridgePresenter(self, didSelectRoomWithId: roomId)
    }
    
    func roomCoordinatorDidLeaveRoom(_ coordinator: RoomCoordinatorProtocol) {
        self.delegate?.roomCoordinatorBridgePresenterDidLeaveRoom(self)
    }
    
    func roomCoordinatorDidCancelRoomPreview(_ coordinator: RoomCoordinatorProtocol) {
        self.delegate?.roomCoordinatorBridgePresenterDidCancelRoomPreview(self)
    }
    
    func roomCoordinatorDidDismissInteractively(_ coordinator: RoomCoordinatorProtocol) {
        self.delegate?.roomCoordinatorBridgePresenterDidDismissInteractively(self)
    }
}
