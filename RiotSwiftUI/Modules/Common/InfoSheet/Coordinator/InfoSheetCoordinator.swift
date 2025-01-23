//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CommonKit
import SwiftUI

struct InfoSheetCoordinatorParameters {
    let title: String
    let description: String
    let action: InfoSheet.Action
    let parentSize: CGSize?
}

final class InfoSheetCoordinator: Coordinator, Presentable {
    private let parameters: InfoSheetCoordinatorParameters
    private let infoSheetHostingController: UIViewController
    private var infoSheetViewModel: InfoSheetViewModelProtocol

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((InfoSheetViewModelResult) -> Void)?
    
    init(parameters: InfoSheetCoordinatorParameters) {
        self.parameters = parameters
        
        let viewModel = InfoSheetViewModel(title: parameters.title, description: parameters.description, action: parameters.action)
        let view = InfoSheet(viewModel: viewModel.context)
        infoSheetViewModel = viewModel
        let controller = VectorHostingController(rootView: view)
        infoSheetHostingController = controller
        setupPresentation(of: controller)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[InfoSheetCoordinator] did start.")
        infoSheetViewModel.completion = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[InfoSheetCoordinator] InfoSheetViewModel did complete with result: \(result).")
            self.completion?(result)
        }
    }
    
    func toPresentable() -> UIViewController {
        infoSheetHostingController
    }
}

private extension InfoSheetCoordinator {
    // The bottom sheet should be presented with the content intrinsic height as for design requirement
    // We can do it easily just on iOS 16+
    func setupPresentation(of viewController: VectorHostingController) {
        let detents: [VectorHostingBottomSheetPreferences.Detent]
        
        if
            #available(iOS 16, *),
            let parentSize = parameters.parentSize {
            
            let intrisincSize = viewController.view.systemLayoutSizeFitting(.init(width: parentSize.width, height: UIView.layoutFittingCompressedSize.height),
                                                                            withHorizontalFittingPriority: .defaultHigh,
                                                                            verticalFittingPriority: .defaultLow)
            
            detents = [.custom(height: intrisincSize.height), .large]
        } else {
            detents = [.medium, .large]
        }
        
        viewController.bottomSheetPreferences = .init(detents: detents, cornerRadius: 24)
        viewController.bottomSheetPreferences?.setup(viewController: viewController)
    }
}
