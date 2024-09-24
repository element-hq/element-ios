// File created from FlowTemplate
// $ createRootCoordinator.sh Room2 RoomInfo RoomInfoList
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation
import MatrixSDK

@objc protocol RoomInfoCoordinatorBridgePresenterDelegate {
    func roomInfoCoordinatorBridgePresenterDelegateDidComplete(_ coordinatorBridgePresenter: RoomInfoCoordinatorBridgePresenter)
    func roomInfoCoordinatorBridgePresenter(_ coordinatorBridgePresenter: RoomInfoCoordinatorBridgePresenter, didRequestMentionForMember member: MXRoomMember)
    func roomInfoCoordinatorBridgePresenterDelegateDidLeaveRoom(_ coordinatorBridgePresenter: RoomInfoCoordinatorBridgePresenter)
    func roomInfoCoordinatorBridgePresenter(_ coordinatorBridgePresenter: RoomInfoCoordinatorBridgePresenter, didReplaceRoomWithReplacementId roomId: String)
    func roomInfoCoordinatorBridgePresenter(_ coordinator: RoomInfoCoordinatorBridgePresenter, viewEventInTimeline event: MXEvent)
    func roomInfoCoordinatorBridgePresenterDidRequestReportRoom(_ coordinatorBridgePresenter: RoomInfoCoordinatorBridgePresenter)
}

/// RoomInfoCoordinatorBridgePresenter enables to start RoomInfoCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
@objcMembers
final class RoomInfoCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let coordinatorParameters: RoomInfoCoordinatorParameters
    private var coordinator: RoomInfoCoordinator?
    private var navigationType: NavigationType = .present
    
    private enum NavigationType {
        case present
        case push
    }
    
    // MARK: Public
    
    weak var delegate: RoomInfoCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(parameters: RoomInfoCoordinatorParameters) {
        self.coordinatorParameters = parameters
        super.init()
    }
    
    // MARK: - Public
    
    // NOTE: Default value feature is not compatible with Objective-C.
    // func present(from viewController: UIViewController, animated: Bool) {
    //     self.present(from: viewController, animated: animated)
    // }
    
    func present(from viewController: UIViewController, animated: Bool) {
        let roomInfoCoordinator = RoomInfoCoordinator(parameters: self.coordinatorParameters)
        roomInfoCoordinator.delegate = self
        let presentable = roomInfoCoordinator.toPresentable()
        presentable.presentationController?.delegate = self
        viewController.present(presentable, animated: animated, completion: nil)
        roomInfoCoordinator.start()
        
        self.coordinator = roomInfoCoordinator
        self.navigationType = .present
    }
    
    func push(from navigationController: UINavigationController, animated: Bool) {
        let navigationRouter = NavigationRouterStore.shared.navigationRouter(for: navigationController)
        
        let roomInfoCoordinator = RoomInfoCoordinator(parameters: self.coordinatorParameters, navigationRouter: navigationRouter)
        roomInfoCoordinator.delegate = self
        roomInfoCoordinator.start()
        
        self.coordinator = roomInfoCoordinator
        self.navigationType = .push
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let coordinator = self.coordinator else {
            return
        }
        switch navigationType {
        case .present:
            coordinator.toPresentable().dismiss(animated: animated) {
                self.coordinator = nil

                if let completion = completion {
                    completion()
                }
            }
        case .push:
            guard let navigationController = coordinator.toPresentable() as? UINavigationController else {
                return
            }
            navigationController.popViewController(animated: animated)
            self.coordinator = nil

            if let completion = completion {
                completion()
            }
        }
    }
}

// MARK: - RoomInfoCoordinatorDelegate
extension RoomInfoCoordinatorBridgePresenter: RoomInfoCoordinatorDelegate {
    
    func roomInfoCoordinatorDidComplete(_ coordinator: RoomInfoCoordinatorType) {
        self.delegate?.roomInfoCoordinatorBridgePresenterDelegateDidComplete(self)
    }
    
    func roomInfoCoordinator(_ coordinator: RoomInfoCoordinatorType, didRequestMentionForMember member: MXRoomMember) {
        self.delegate?.roomInfoCoordinatorBridgePresenter(self, didRequestMentionForMember: member)
    }
    
    func roomInfoCoordinatorDidLeaveRoom(_ coordinator: RoomInfoCoordinatorType) {
        self.delegate?.roomInfoCoordinatorBridgePresenterDelegateDidLeaveRoom(self)
    }
    
    func roomInfoCoordinator(_ coordinator: RoomInfoCoordinatorType, didReplaceRoomWithReplacementId roomId: String) {
        self.delegate?.roomInfoCoordinatorBridgePresenter(self, didReplaceRoomWithReplacementId: roomId)
    }
    
    func roomInfoCoordinator(_ coordinator: RoomInfoCoordinatorType, viewEventInTimeline event: MXEvent) {
        self.delegate?.roomInfoCoordinatorBridgePresenter(self, viewEventInTimeline: event)
    }
    
    func roomInfoCoordinatorDidRequestReportRoom(_ coordinator: RoomInfoCoordinatorType) {
        self.delegate?.roomInfoCoordinatorBridgePresenterDidRequestReportRoom(self)
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension RoomInfoCoordinatorBridgePresenter: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.delegate?.roomInfoCoordinatorBridgePresenterDelegateDidComplete(self)
    }
    
}
