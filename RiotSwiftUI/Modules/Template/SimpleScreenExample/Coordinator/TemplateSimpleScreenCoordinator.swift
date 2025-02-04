//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CommonKit
import SwiftUI

struct TemplateSimpleScreenCoordinatorParameters {
    let promptType: TemplateSimpleScreenPromptType
}

final class TemplateSimpleScreenCoordinator: Coordinator, Presentable {
    private let parameters: TemplateSimpleScreenCoordinatorParameters
    private let templateSimpleScreenHostingController: UIViewController
    private var templateSimpleScreenViewModel: TemplateSimpleScreenViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((TemplateSimpleScreenViewModelResult) -> Void)?
    
    init(parameters: TemplateSimpleScreenCoordinatorParameters) {
        self.parameters = parameters
        
        let viewModel = TemplateSimpleScreenViewModel(promptType: parameters.promptType)
        let view = TemplateSimpleScreen(viewModel: viewModel.context)
        templateSimpleScreenViewModel = viewModel
        templateSimpleScreenHostingController = VectorHostingController(rootView: view)
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: templateSimpleScreenHostingController)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[TemplateSimpleScreenCoordinator] did start.")
        templateSimpleScreenViewModel.completion = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[TemplateSimpleScreenCoordinator] TemplateSimpleScreenViewModel did complete with result: \(result).")
            self.completion?(result)
        }
    }
    
    func toPresentable() -> UIViewController {
        templateSimpleScreenHostingController
    }
    
    // MARK: - Private
    
    /// Show an activity indicator whilst loading.
    /// - Parameters:
    ///   - label: The label to show on the indicator.
    ///   - isInteractionBlocking: Whether the indicator should block any user interaction.
    private func startLoading(label: String = VectorL10n.loading, isInteractionBlocking: Bool = true) {
        loadingIndicator = indicatorPresenter.present(.loading(label: label, isInteractionBlocking: isInteractionBlocking))
    }
    
    /// Hide the currently displayed activity indicator.
    private func stopLoading() {
        loadingIndicator = nil
    }
}
