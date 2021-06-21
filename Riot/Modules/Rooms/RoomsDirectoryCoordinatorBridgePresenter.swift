// File created from FlowTemplate
// $ createRootCoordinator.sh Rooms2 RoomsDirectory ShowDirectory
/*
 Copyright 2020 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation

@objc protocol RoomsDirectoryCoordinatorBridgePresenterDelegate {
    func roomsDirectoryCoordinatorBridgePresenterDelegateDidComplete(_ coordinatorBridgePresenter: RoomsDirectoryCoordinatorBridgePresenter)
    func roomsDirectoryCoordinatorBridgePresenterDelegate(_ coordinatorBridgePresenter: RoomsDirectoryCoordinatorBridgePresenter, didSelectRoom room: MXPublicRoom)
    func roomsDirectoryCoordinatorBridgePresenterDelegateDidTapCreateNewRoom(_ coordinatorBridgePresenter: RoomsDirectoryCoordinatorBridgePresenter)
    func roomsDirectoryCoordinatorBridgePresenterDelegate(_ coordinatorBridgePresenter: RoomsDirectoryCoordinatorBridgePresenter, didSelectRoomWithIdOrAlias roomIdOrAlias: String)
}

/// RoomsDirectoryCoordinatorBridgePresenter enables to start RoomsDirectoryCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
@objcMembers
final class RoomsDirectoryCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let dataSource: PublicRoomsDirectoryDataSource
    private var coordinator: RoomsDirectoryCoordinator?
    
    // MARK: Public
    
    weak var delegate: RoomsDirectoryCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, dataSource: PublicRoomsDirectoryDataSource) {
        self.session = session
        self.dataSource = dataSource
        super.init()
    }
    
    // MARK: - Public
    
    // NOTE: Default value feature is not compatible with Objective-C.
    // func present(from viewController: UIViewController, animated: Bool) {
    //     self.present(from: viewController, animated: animated)
    // }
    
    func present(from viewController: UIViewController, animated: Bool) {
        let roomsDirectoryCoordinator = RoomsDirectoryCoordinator(session: self.session, dataSource: dataSource)
        roomsDirectoryCoordinator.delegate = self
        let presentable = roomsDirectoryCoordinator.toPresentable()
        presentable.presentationController?.delegate = self
        viewController.present(presentable, animated: animated, completion: nil)
        roomsDirectoryCoordinator.start()
        
        self.coordinator = roomsDirectoryCoordinator
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let coordinator = self.coordinator else {
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

// MARK: - RoomsDirectoryCoordinatorDelegate
extension RoomsDirectoryCoordinatorBridgePresenter: RoomsDirectoryCoordinatorDelegate {
    
    func roomsDirectoryCoordinator(_ coordinator: RoomsDirectoryCoordinatorType, didSelectRoom room: MXPublicRoom) {
        self.delegate?.roomsDirectoryCoordinatorBridgePresenterDelegate(self, didSelectRoom: room)
    }
    
    func roomsDirectoryCoordinatorDidTapCreateNewRoom(_ coordinator: RoomsDirectoryCoordinatorType) {
        self.delegate?.roomsDirectoryCoordinatorBridgePresenterDelegateDidTapCreateNewRoom(self)
    }
    
    func roomsDirectoryCoordinatorDidComplete(_ coordinator: RoomsDirectoryCoordinatorType) {
        self.delegate?.roomsDirectoryCoordinatorBridgePresenterDelegateDidComplete(self)
    }
    
    func roomsDirectoryCoordinator(_ coordinator: RoomsDirectoryCoordinatorType, didSelectRoomWithIdOrAlias roomIdOrAlias: String) {
        self.delegate?.roomsDirectoryCoordinatorBridgePresenterDelegate(self, didSelectRoomWithIdOrAlias: roomIdOrAlias)
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension RoomsDirectoryCoordinatorBridgePresenter: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.delegate?.roomsDirectoryCoordinatorBridgePresenterDelegateDidComplete(self)
    }
    
}
