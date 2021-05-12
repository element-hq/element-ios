/*
 Copyright 2019 New Vector Ltd
 
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
