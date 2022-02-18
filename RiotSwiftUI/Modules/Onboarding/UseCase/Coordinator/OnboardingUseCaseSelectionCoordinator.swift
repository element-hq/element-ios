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

final class OnboardingUseCaseSelectionCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let onboardingUseCaseHostingController: UIViewController
    private var onboardingUseCaseViewModel: OnboardingUseCaseViewModelProtocol
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((OnboardingUseCaseViewModelResult) -> Void)?
    
    // MARK: - Setup
    
    @available(iOS 14.0, *)
    init() {
        let viewModel = OnboardingUseCaseViewModel()
        let view = OnboardingUseCaseSelectionScreen(viewModel: viewModel.context)
        onboardingUseCaseViewModel = viewModel
        
        let hostingController = VectorHostingController(rootView: view)
        hostingController.vc_removeBackTitle()
        hostingController.enableNavigationBarScrollEdgesAppearance = true
        onboardingUseCaseHostingController = hostingController
    }
    
    // MARK: - Public
    func start() {
        MXLog.debug("[OnboardingUseCaseSelectionCoordinator] did start.")
        onboardingUseCaseViewModel.completion = { [weak self] result in
            MXLog.debug("[OnboardingUseCaseSelectionCoordinator] OnboardingUseCaseViewModel did complete with result: \(result).")
            guard let self = self else { return }
            self.completion?(result)
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.onboardingUseCaseHostingController
    }
}
