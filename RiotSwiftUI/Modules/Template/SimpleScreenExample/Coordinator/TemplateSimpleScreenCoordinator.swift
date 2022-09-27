//
// Copyright 2021 New Vector Ltd
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
