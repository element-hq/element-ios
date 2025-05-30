//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//
import Foundation

@objc protocol RoomNotificationSettingsCoordinatorBridgePresenterDelegate {
    func roomNotificationSettingsCoordinatorBridgePresenterDelegateDidComplete(_ coordinatorBridgePresenter: RoomNotificationSettingsCoordinatorBridgePresenter)
}

/// RoomNotificationSettingsCoordinatorBridgePresenter enables to start RoomNotificationSettingsCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
/// It breaks the Coordinator abstraction and it has been introduced for Objective-C compatibility (mainly for integration in legacy view controllers).
/// Each bridge should be removed once the underlying Coordinator has been integrated by another Coordinator.
@objcMembers
final class RoomNotificationSettingsCoordinatorBridgePresenter: NSObject {
    // MARK: - Properties
    
    // MARK: Private
    
    private let room: MXRoom
    private var coordinator: RoomNotificationSettingsCoordinator?
    
    // MARK: Public
    
    weak var delegate: RoomNotificationSettingsCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(room: MXRoom) {
        self.room = room
        super.init()
    }
    
    // MARK: - Public
    
    // NOTE: Default value feature is not compatible with Objective-C.
    // func present(from viewController: UIViewController, animated: Bool) {
    //     self.present(from: viewController, animated: animated)
    // }
    
    func present(from viewController: UIViewController, animated: Bool) {
        let roomNotificationSettingsCoordinator = RoomNotificationSettingsCoordinator(room: room)
        roomNotificationSettingsCoordinator.delegate = self
        let presentable = roomNotificationSettingsCoordinator.toPresentable()
        let navigationController = RiotNavigationController(rootViewController: presentable)
        navigationController.modalPresentationStyle = .formSheet
        presentable.presentationController?.delegate = self
        viewController.present(navigationController, animated: animated, completion: nil)
        roomNotificationSettingsCoordinator.start()
        
        coordinator = roomNotificationSettingsCoordinator
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

// MARK: - RoomNotificationSettingsCoordinatorDelegate

extension RoomNotificationSettingsCoordinatorBridgePresenter: RoomNotificationSettingsCoordinatorDelegate {
    func roomNotificationSettingsCoordinatorDidCancel(_ coordinator: RoomNotificationSettingsCoordinatorType) {
        delegate?.roomNotificationSettingsCoordinatorBridgePresenterDelegateDidComplete(self)
    }
    
    func roomNotificationSettingsCoordinatorDidComplete(_ coordinator: RoomNotificationSettingsCoordinatorType) {
        delegate?.roomNotificationSettingsCoordinatorBridgePresenterDelegateDidComplete(self)
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension RoomNotificationSettingsCoordinatorBridgePresenter: UIAdaptivePresentationControllerDelegate {
    func roomNotificationSettingsCoordinatorDidComplete(_ presentationController: UIPresentationController) {
        delegate?.roomNotificationSettingsCoordinatorBridgePresenterDelegateDidComplete(self)
    }
}
