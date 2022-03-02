// File created from FlowTemplate
// $ createRootCoordinator.sh CreateRoom CreateRoom EnterNewRoomDetails
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

@objc protocol CreateRoomCoordinatorBridgePresenterDelegate {
    func createRoomCoordinatorBridgePresenterDelegate(_ coordinatorBridgePresenter: CreateRoomCoordinatorBridgePresenter, didCreateNewRoom room: MXRoom)
    func createRoomCoordinatorBridgePresenterDelegate(_ coordinatorBridgePresenter: CreateRoomCoordinatorBridgePresenter, didAddRoomsWithIds roomIds: [String])
    func createRoomCoordinatorBridgePresenterDelegateDidCancel(_ coordinatorBridgePresenter: CreateRoomCoordinatorBridgePresenter)
}

/// CreateRoomCoordinatorBridgePresenter enables to start CreateRoomCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
@objcMembers
final class CreateRoomCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: CreateRoomCoordinatorParameter
    private var coordinator: CreateRoomCoordinator?
    
    // MARK: Public
    
    weak var delegate: CreateRoomCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(parameters: CreateRoomCoordinatorParameter) {
        self.parameters = parameters
        super.init()
    }
    
    // MARK: - Public
    
    // NOTE: Default value feature is not compatible with Objective-C.
    // func present(from viewController: UIViewController, animated: Bool) {
    //     self.present(from: viewController, animated: animated)
    // }
    
    func present(from viewController: UIViewController, animated: Bool) {
        let createRoomCoordinator = CreateRoomCoordinator(parameters: self.parameters)
        createRoomCoordinator.delegate = self
        let presentable = createRoomCoordinator.toPresentable()
        presentable.presentationController?.delegate = self
        viewController.present(presentable, animated: animated, completion: nil)
        createRoomCoordinator.start()
        
        self.coordinator = createRoomCoordinator
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

// MARK: - CreateRoomCoordinatorDelegate

extension CreateRoomCoordinatorBridgePresenter: CreateRoomCoordinatorDelegate {
    
    func createRoomCoordinator(_ coordinator: CreateRoomCoordinatorType, didCreateNewRoom room: MXRoom) {
        self.delegate?.createRoomCoordinatorBridgePresenterDelegate(self, didCreateNewRoom: room)
    }
    
    func createRoomCoordinator(_ coordinator: CreateRoomCoordinatorType, didAddRoomsWithIds roomIds: [String]) {
        self.delegate?.createRoomCoordinatorBridgePresenterDelegate(self, didAddRoomsWithIds: roomIds)
    }

    func createRoomCoordinatorDidCancel(_ coordinator: CreateRoomCoordinatorType) {
        self.delegate?.createRoomCoordinatorBridgePresenterDelegateDidCancel(self)
    }
    
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension CreateRoomCoordinatorBridgePresenter: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.delegate?.createRoomCoordinatorBridgePresenterDelegateDidCancel(self)
    }
    
}
