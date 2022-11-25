// 
// Copyright 2022 New Vector Ltd
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

@objc protocol MessageContextMenuCoordinatorBridgePresenterDelegate {
    func messageContextMenuCoordinatorBridgePresenterDelegateDidComplete(_ coordinatorBridgePresenter: MessageContextMenuCoordinatorBridgePresenter)
    func messageContextMenuCoordinatorBridgePresenterDelegate(_ coordinatorBridgePresenter: MessageContextMenuCoordinatorBridgePresenter, didSelectActionOfType actionType: MessageContextMenuActionType, for event: MXEvent, from cell: MXKRoomBubbleTableViewCell)
    func messageContextMenuCoordinatorBridgePresenterDelegate(_ coordinatorBridgePresenter: MessageContextMenuCoordinatorBridgePresenter, didUpdateReaction reaction: String, hasSelected isSelected: Bool, for event: MXEvent)
    func messageContextMenuCoordinatorBridgePresenterDelegate(_ coordinatorBridgePresenter: MessageContextMenuCoordinatorBridgePresenter, displayMoreReactionsFor event: MXEvent)
}

/// MessageContextMenuCoordinatorBridgePresenter enables to start MessageContextMenuCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
/// It breaks the Coordinator abstraction and it has been introduced for Objective-C compatibility (mainly for integration in legacy view controllers).
/// Each bridge should be removed once the underlying Coordinator has been integrated by another Coordinator.
@objcMembers
final class MessageContextMenuCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private var event: MXEvent!
    private var cell: MXKRoomBubbleTableViewCell!
    private var roomDataSource: MXKRoomDataSource!
    
    private var coordinator: (Coordinator & Presentable)?

    // MARK: Public
    
    weak var delegate: MessageContextMenuCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
        super.init()
    }
    
    // MARK: - Public
    
    // NOTE: Default value feature is not compatible with Objective-C.
    // func present(from viewController: UIViewController, animated: Bool) {
    //     self.present(from: viewController, animated: animated)
    // }
    
    @available(iOS 14.0, *)
    func present(from viewController: UIViewController, event: MXEvent, cell: MXKRoomBubbleTableViewCell, roomDataSource: MXKRoomDataSource, canEndPoll: Bool, animated: Bool) {
        self.event = event
        self.cell = cell
        self.roomDataSource = roomDataSource
        
        let coordinator = MessageContextMenuCoordinator(parameters: MessageContextMenuCoordinatorParameters(session: session, event: event, cell: cell, roomDataSource: roomDataSource, canEndPoll: canEndPoll))
        coordinator.completion = { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .cancel:
                self.delegate?.messageContextMenuCoordinatorBridgePresenterDelegateDidComplete(self)
            case .done(let actionType):
                self.delegate?.messageContextMenuCoordinatorBridgePresenterDelegate(self, didSelectActionOfType: actionType, for: self.event, from: self.cell)
            case .updateReaction(let reaction, let isSelected):
                self.delegate?.messageContextMenuCoordinatorBridgePresenterDelegate(self, didUpdateReaction: reaction, hasSelected: isSelected, for: self.event)
            case .moreReactions:
                self.delegate?.messageContextMenuCoordinatorBridgePresenterDelegate(self, displayMoreReactionsFor: self.event)
            }
        }
        let presentable = coordinator.toPresentable()
//        let navigationController = RiotNavigationController(rootViewController: presentable)
//        navigationController.modalPresentationStyle = .formSheet
//        presentable.presentationController?.delegate = self
//        viewController.present(navigationController, animated: animated, completion: nil)
        
        presentable.modalPresentationStyle = .overFullScreen
        presentable.modalTransitionStyle = .crossDissolve
        viewController.present(presentable, animated: false)

        coordinator.start()
        
        self.coordinator = coordinator
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

// MARK: - UIAdaptivePresentationControllerDelegate

extension MessageContextMenuCoordinatorBridgePresenter: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.delegate?.messageContextMenuCoordinatorBridgePresenterDelegateDidComplete(self)
    }
    
}
