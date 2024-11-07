/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

@objc protocol ReactionHistoryCoordinatorBridgePresenterDelegate {
    func reactionHistoryCoordinatorBridgePresenterDelegateDidClose(_ coordinatorBridgePresenter: ReactionHistoryCoordinatorBridgePresenter)
}

/// ReactionHistoryCoordinatorBridgePresenter enables to start ReactionHistoryCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
@objcMembers
final class ReactionHistoryCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let roomId: String
    private let eventId: String
    private var coordinator: ReactionHistoryCoordinator?
    
    // MARK: Public
    
    var isPresenting: Bool {
        return self.coordinator != nil
    }
    
    weak var delegate: ReactionHistoryCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, roomId: String, eventId: String) {
        self.session = session
        self.roomId = roomId
        self.eventId = eventId
        super.init()
    }
    
    // MARK: - Public
    
    func present(from viewController: UIViewController, animated: Bool) {
        
        let reactionHistoryCoordinator = ReactionHistoryCoordinator(session: self.session, roomId: self.roomId, eventId: self.eventId)
        reactionHistoryCoordinator.delegate = self
        
        let coordinatorPresentable = reactionHistoryCoordinator.toPresentable()
        coordinatorPresentable.modalPresentationStyle = .formSheet
        coordinatorPresentable.presentationController?.delegate = self
        viewController.present(coordinatorPresentable, animated: animated, completion: nil)
        
        reactionHistoryCoordinator.start()
        
        self.coordinator = reactionHistoryCoordinator
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

// MARK: - ReactionHistoryCoordinatorDelegate
extension ReactionHistoryCoordinatorBridgePresenter: ReactionHistoryCoordinatorDelegate {
    func reactionHistoryCoordinatorDidClose(_ coordinator: ReactionHistoryCoordinatorType) {
        self.delegate?.reactionHistoryCoordinatorBridgePresenterDelegateDidClose(self)
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension ReactionHistoryCoordinatorBridgePresenter: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.delegate?.reactionHistoryCoordinatorBridgePresenterDelegateDidClose(self)
    }
    
}
