// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import WysiwygComposer

protocol ComposerLinkActionBridgePresenterDelegate: AnyObject {
    func didCancel()
    func didDismissInteractively()
    func didRequestLinkOperation(_ linkOperation: WysiwygLinkOperation)
}

final class ComposerLinkActionBridgePresenter: NSObject {
    private var coordinator: ComposerLinkActionCoordinator?
    private var linkAction: LinkAction
    
    weak var delegate: ComposerLinkActionBridgePresenterDelegate?
    
    init(linkAction: LinkActionWrapper) {
        self.linkAction = linkAction.linkAction
        super.init()
    }
    
    func present(from viewController: UIViewController, animated: Bool) {
        let composerLinkActionCoordinator = ComposerLinkActionCoordinator(linkAction: linkAction)
        composerLinkActionCoordinator.callback = { [weak self] action in
            switch action {
            case .didTapCancel:
                self?.delegate?.didCancel()
            case .didDismissInteractively:
                self?.delegate?.didDismissInteractively()
            case let .didRequestLinkOperation(linkOperation):
                self?.delegate?.didRequestLinkOperation(linkOperation)
            }
        }
        let presentable = composerLinkActionCoordinator.toPresentable()
        viewController.present(presentable, animated: animated, completion: nil)
        composerLinkActionCoordinator.start()
        coordinator = composerLinkActionCoordinator
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let coordinator = coordinator else {
            return
        }
        // Dismiss modal
        coordinator.toPresentable().dismiss(animated: animated) {
            self.coordinator = nil
            completion?()
        }
    }
}
