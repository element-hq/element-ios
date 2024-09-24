// File created from FlowTemplate
// $ createRootCoordinator.sh Spaces/SpaceMembers SpaceMemberList ShowSpaceMemberList
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

@objc protocol SpaceMembersCoordinatorBridgePresenterDelegate {
    func spaceMembersCoordinatorBridgePresenterDelegateDidComplete(_ coordinatorBridgePresenter: SpaceMembersCoordinatorBridgePresenter)
}

/// SpaceMembersCoordinatorBridgePresenter enables to start SpaceMemberListCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
/// It breaks the Coordinator abstraction and it has been introduced for Objective-C compatibility (mainly for integration in legacy view controllers).
/// Each bridge should be removed once the underlying Coordinator has been integrated by another Coordinator.
@objcMembers
final class SpaceMembersCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let userSessionsService: UserSessionsService
    private let session: MXSession
    private let spaceId: String
    private var coordinator: SpaceMembersCoordinator?
    
    // MARK: Public
    
    weak var delegate: SpaceMembersCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(userSessionsService: UserSessionsService, session: MXSession, spaceId: String) {
        self.userSessionsService = userSessionsService
        self.session = session
        self.spaceId = spaceId
        super.init()
    }
    
    // MARK: - Public
    
    func present(from viewController: UIViewController, animated: Bool) {
        let parameters = SpaceMembersCoordinatorParameters(userSessionsService: self.userSessionsService, session: self.session, spaceId: self.spaceId)
        let spaceMemberListCoordinator = SpaceMembersCoordinator(parameters: parameters)
        spaceMemberListCoordinator.delegate = self
        let presentable = spaceMemberListCoordinator.toPresentable()
        presentable.presentationController?.delegate = self
        viewController.present(presentable, animated: animated, completion: nil)
        spaceMemberListCoordinator.start()
        
        self.coordinator = spaceMemberListCoordinator
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

// MARK: - SpaceMembersCoordinatorDelegate
extension SpaceMembersCoordinatorBridgePresenter: SpaceMembersCoordinatorDelegate {
    func spaceMembersCoordinatorDidCancel(_ coordinator: SpaceMembersCoordinatorType) {
        self.delegate?.spaceMembersCoordinatorBridgePresenterDelegateDidComplete(self)
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension SpaceMembersCoordinatorBridgePresenter: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.delegate?.spaceMembersCoordinatorBridgePresenterDelegateDidComplete(self)
    }
    
}
