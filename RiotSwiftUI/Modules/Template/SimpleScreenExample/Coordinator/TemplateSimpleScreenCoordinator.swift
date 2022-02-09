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

import SwiftUI

struct TemplateSimpleScreenCoordinatorParameters {
    let promptType: TemplateSimpleScreenPromptType
}

final class TemplateSimpleScreenCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: TemplateSimpleScreenCoordinatorParameters
    private let templateSimpleScreenHostingController: UIViewController
    private var templateSimpleScreenViewModel: TemplateSimpleScreenViewModelProtocol
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((TemplateSimpleScreenViewModelResult) -> Void)?
    
    // MARK: - Setup
    
    @available(iOS 14.0, *)
    init(parameters: TemplateSimpleScreenCoordinatorParameters) {
        self.parameters = parameters
        
        let viewModel = TemplateSimpleScreenViewModel(promptType: parameters.promptType)
        let view = TemplateSimpleScreen(viewModel: viewModel.context)
        templateSimpleScreenViewModel = viewModel
        templateSimpleScreenHostingController = VectorHostingController(rootView: view)
    }
    
    // MARK: - Public
    func start() {
        MXLog.debug("[TemplateSimpleScreenCoordinator] did start.")
        templateSimpleScreenViewModel.completion = { [weak self] result in
            MXLog.debug("[TemplateSimpleScreenCoordinator] TemplateSimpleScreenViewModel did complete with result: \(result).")
            guard let self = self else { return }
            self.completion?(result)
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.templateSimpleScreenHostingController
    }
}
