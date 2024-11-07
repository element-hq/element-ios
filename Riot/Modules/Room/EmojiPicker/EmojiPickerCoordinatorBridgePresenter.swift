/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit

@objc protocol EmojiPickerCoordinatorBridgePresenterDelegate {
    func emojiPickerCoordinatorBridgePresenter(_ coordinatorBridgePresenter: EmojiPickerCoordinatorBridgePresenter, didAddEmoji emoji: String, forEventId eventId: String)
    func emojiPickerCoordinatorBridgePresenter(_ coordinatorBridgePresenter: EmojiPickerCoordinatorBridgePresenter, didRemoveEmoji emoji: String, forEventId eventId: String)
    func emojiPickerCoordinatorBridgePresenterDidCancel(_ coordinatorBridgePresenter: EmojiPickerCoordinatorBridgePresenter)
}

/// EmojiPickerCoordinatorBridgePresenter enables to start EmojiPickerCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
@objcMembers
final class EmojiPickerCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let roomId: String
    private let eventId: String
    private var coordinator: EmojiPickerCoordinator?
    
    // MARK: Public
    
    weak var delegate: EmojiPickerCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, roomId: String, eventId: String) {
        self.session = session
        self.roomId = roomId
        self.eventId = eventId
        super.init()
    }
    
    // MARK: - Public
    
    func present(from viewController: UIViewController,
                 sourceView: UIView?,
                 sourceRect: CGRect,
                 animated: Bool) {
        let emojiPickerCoordinator = EmojiPickerCoordinator(session: self.session, roomId: self.roomId, eventId: self.eventId)
        emojiPickerCoordinator.delegate = self
        
        let emojiPickerPresentable = emojiPickerCoordinator.toPresentable()
        
        if let sourceView = sourceView {
            
            emojiPickerPresentable.modalPresentationStyle = .popover
            
            if let popoverPresentationController = emojiPickerPresentable.popoverPresentationController {
                popoverPresentationController.sourceView = sourceView
                
                let finalSourceRect: CGRect
                
                if sourceRect != CGRect.null {
                    finalSourceRect = sourceRect
                } else {
                    finalSourceRect = sourceView.bounds
                }
                
                popoverPresentationController.sourceRect = finalSourceRect
            }
        }
        
        viewController.present(emojiPickerPresentable, animated: animated, completion: nil)
        
        emojiPickerCoordinator.start()
        
        self.coordinator = emojiPickerCoordinator
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

// MARK: - EmojiPickerCoordinatorDelegate
extension EmojiPickerCoordinatorBridgePresenter: EmojiPickerCoordinatorDelegate {
    
    func emojiPickerCoordinator(_ coordinator: EmojiPickerCoordinatorType, didAddEmoji emoji: String, forEventId eventId: String) {
        self.delegate?.emojiPickerCoordinatorBridgePresenter(self, didAddEmoji: emoji, forEventId: eventId)
    }
    
    func emojiPickerCoordinator(_ coordinator: EmojiPickerCoordinatorType, didRemoveEmoji emoji: String, forEventId eventId: String) {
        self.delegate?.emojiPickerCoordinatorBridgePresenter(self, didRemoveEmoji: emoji, forEventId: eventId)
    }
    
    func emojiPickerCoordinatorDidCancel(_ coordinator: EmojiPickerCoordinatorType) {
        self.delegate?.emojiPickerCoordinatorBridgePresenterDidCancel(self)
    }
}
