// File created from FlowTemplate
// $ createRootCoordinator.sh CreateRoom CreateRoom EnterNewRoomDetails
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
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
