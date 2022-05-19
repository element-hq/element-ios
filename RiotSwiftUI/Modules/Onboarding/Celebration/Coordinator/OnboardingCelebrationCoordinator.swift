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

struct OnboardingCelebrationCoordinatorParameters {
    let userSession: UserSession
}

final class OnboardingCelebrationCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: OnboardingCelebrationCoordinatorParameters
    private let onboardingCelebrationHostingController: VectorHostingController
    private var onboardingCelebrationViewModel: OnboardingCelebrationViewModelProtocol
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((UserSession) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: OnboardingCelebrationCoordinatorParameters) {
        self.parameters = parameters
        
        let viewModel = OnboardingCelebrationViewModel()
        let view = OnboardingCelebrationScreen(viewModel: viewModel.context)
        onboardingCelebrationViewModel = viewModel
        onboardingCelebrationHostingController = VectorHostingController(rootView: view)
        onboardingCelebrationHostingController.enableNavigationBarScrollEdgeAppearance = true
    }
    
    // MARK: - Public
    func start() {
        MXLog.debug("[OnboardingCelebrationCoordinator] did start.")
        onboardingCelebrationViewModel.completion = { [weak self] in
            guard let self = self else { return }
            MXLog.debug("[OnboardingCelebrationCoordinator] OnboardingCelebrationViewModel did complete.")
            self.completion?(self.parameters.userSession)
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.onboardingCelebrationHostingController
    }
}
