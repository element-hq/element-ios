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
