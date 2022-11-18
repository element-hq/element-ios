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

import SwiftUI

/// Actions returned by the coordinator callback
enum ComposerCreateActionListCoordinatorAction {
    case done(ComposerCreateAction)
    case toggleTextFormatting(Bool)
    case cancel
}

final class ComposerCreateActionListCoordinator: NSObject, Coordinator, Presentable, UISheetPresentationControllerDelegate {
    // MARK: - Properties
    
    // MARK: Private
    
    private let hostingController: UIViewController
    private var view: ComposerCreateActionList
    private var viewModel: ComposerCreateActionListViewModel
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: ((ComposerCreateActionListCoordinatorAction) -> Void)?
    
    // MARK: - Setup
    
    init(actions: [ComposerCreateAction], wysiwygEnabled: Bool, textFormattingEnabled: Bool) {
        viewModel = ComposerCreateActionListViewModel(initialViewState: ComposerCreateActionListViewState(
            actions: actions,
            wysiwygEnabled: wysiwygEnabled,
            bindings: ComposerCreateActionListBindings(textFormattingEnabled: textFormattingEnabled)))
        view = ComposerCreateActionList(viewModel: viewModel.context)
        let hostingVC = VectorHostingController(rootView: view)
        hostingVC.bottomSheetPreferences = VectorHostingBottomSheetPreferences(
            detents: [.custom(height: 470)],
            prefersGrabberVisible: true,
            cornerRadius: 20,
            prefersScrollingExpandsWhenScrolledToEdge: false
        )
        hostingController = hostingVC
        super.init()
        hostingVC.presentationController?.delegate = self
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[ComposerCreateActionListCoordinator] did start.")
        viewModel.callback = { result in
            switch result {
            case .done(let action):
                self.callback?(.done(action))
            case .toggleTextFormatting(let enabled):
                self.callback?(.toggleTextFormatting(enabled))
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        hostingController
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        callback?(.cancel)
    }
}
