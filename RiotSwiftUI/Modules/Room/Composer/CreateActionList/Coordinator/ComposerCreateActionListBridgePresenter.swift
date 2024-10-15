/*
Copyright 2022-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

@objc protocol ComposerCreateActionListBridgePresenterDelegate {
    func composerCreateActionListBridgePresenterDelegateDidComplete(_ coordinatorBridgePresenter: ComposerCreateActionListBridgePresenter, action: ComposerCreateAction)
    func composerCreateActionListBridgePresenterDelegateDidToggleTextFormatting(_ coordinatorBridgePresenter: ComposerCreateActionListBridgePresenter, enabled: Bool)
    func composerCreateActionListBridgePresenterDidDismissInteractively(_ coordinatorBridgePresenter: ComposerCreateActionListBridgePresenter)
}

/// ComposerCreateActionListBridgePresenter enables to start ComposerCreateActionList from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
/// **WARNING**: This class breaks the Coordinator abstraction and it has been introduced for **Objective-C compatibility only**
/// (mainly for integration in legacy view controllers). Each bridge should be removed once the underlying Coordinator has been integrated by another Coordinator.
@objcMembers
final class ComposerCreateActionListBridgePresenter: NSObject {
    // MARK: - Constants
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let actions: [ComposerCreateAction]
    private let wysiwygEnabled: Bool
    private let textFormattingEnabled: Bool
    private var coordinator: ComposerCreateActionListCoordinator?
    
    // MARK: Public
    
    weak var delegate: ComposerCreateActionListBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(actions: [Int], wysiwygEnabled: Bool, textFormattingEnabled: Bool) {
        self.actions = actions.compactMap {
            ComposerCreateAction(rawValue: $0)
        }
        self.wysiwygEnabled = wysiwygEnabled
        self.textFormattingEnabled = textFormattingEnabled
        super.init()
    }
    
    // MARK: - Public
    
    // NOTE: Default value feature is not compatible with Objective-C.
    // func present(from viewController: UIViewController, animated: Bool) {
    //     self.present(from: viewController, animated: animated)
    // }
    
    func present(from viewController: UIViewController, animated: Bool) {
        let composerCreateActionListCoordinator = ComposerCreateActionListCoordinator(actions: actions,
                                                                                      wysiwygEnabled: wysiwygEnabled,
                                                                                      textFormattingEnabled: textFormattingEnabled)
        composerCreateActionListCoordinator.callback = { [weak self] action in
            guard let self = self else { return }
            switch action {
            case .done(let composeAction):
                self.delegate?.composerCreateActionListBridgePresenterDelegateDidComplete(self, action: composeAction)
            case .toggleTextFormatting(let enabled):
                self.delegate?.composerCreateActionListBridgePresenterDelegateDidToggleTextFormatting(self, enabled: enabled)
            case .cancel:
                self.delegate?.composerCreateActionListBridgePresenterDidDismissInteractively(self)
            }
        }
        let presentable = composerCreateActionListCoordinator.toPresentable()
        viewController.present(presentable, animated: animated, completion: nil)
        composerCreateActionListCoordinator.start()
        
        coordinator = composerCreateActionListCoordinator
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let coordinator = coordinator else {
            return
        }
        // Dismiss modal
        coordinator.toPresentable().dismiss(animated: animated) {
            self.coordinator = nil

            if let completion = completion {
                completion()
            }
        }
    }
}
