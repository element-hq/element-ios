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
