//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
        let isScrollingEnabled: Bool
        if #available(iOS 16, *) {
            isScrollingEnabled = false
        } else {
            isScrollingEnabled = true
        }
        viewModel = ComposerCreateActionListViewModel(initialViewState: ComposerCreateActionListViewState(
            actions: actions,
            wysiwygEnabled: wysiwygEnabled,
            isScrollingEnabled: isScrollingEnabled,
            bindings: ComposerCreateActionListBindings(textFormattingEnabled: textFormattingEnabled)))
        view = ComposerCreateActionList(viewModel: viewModel.context)
        let hostingVC = VectorHostingController(rootView: view)
        let height = hostingVC.sizeThatFits(in: CGSize(width: hostingVC.view.frame.width, height: UIView.layoutFittingCompressedSize.height)).height
        hostingVC.bottomSheetPreferences = VectorHostingBottomSheetPreferences(
            // on iOS 15 custom will be replaced by medium which may require some scrolling
            detents: [.custom(height: height)],
            prefersGrabberVisible: true,
            cornerRadius: 20,
            prefersScrollingExpandsWhenScrolledToEdge: false
        )
        hostingController = hostingVC
        super.init()
        hostingVC.presentationController?.delegate = self
        hostingVC.bottomSheetPreferences?.setup(viewController: hostingVC)
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
