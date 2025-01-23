// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import WysiwygComposer

enum ComposerLinkActionCoordinatorAction {
    case didTapCancel
    case didDismissInteractively
    case didRequestLinkOperation(_ linkOperation: WysiwygLinkOperation)
}

final class ComposerLinkActionCoordinator: NSObject, Coordinator, Presentable {
    var childCoordinators: [Coordinator] = []
    
    private let hostingController: UIViewController
    private let viewModel: ComposerLinkActionViewModel
    
    var callback: ((ComposerLinkActionCoordinatorAction) -> Void)?
    
    init(linkAction: LinkAction) {
        viewModel = ComposerLinkActionViewModel(from: linkAction)
        hostingController = VectorHostingController(rootView: ComposerLinkAction(viewModel: viewModel.context))
        super.init()
        hostingController.presentationController?.delegate = self
    }
    
    func start() {
        viewModel.callback = { [weak self] result in
            switch result {
            case .cancel:
                self?.callback?(.didTapCancel)
            case let .performOperation(linkOperation):
                self?.callback?(.didRequestLinkOperation(linkOperation))
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        hostingController
    }
}

extension ComposerLinkActionCoordinator: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.callback?(.didDismissInteractively)
    }
}
