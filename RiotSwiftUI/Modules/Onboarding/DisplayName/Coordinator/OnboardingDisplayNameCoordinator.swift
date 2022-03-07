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

struct OnboardingDisplayNameCoordinatorParameters {
    let userSession: UserSession
}

@available(iOS 14.0, *)
final class OnboardingDisplayNameCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: OnboardingDisplayNameCoordinatorParameters
    private let onboardingDisplayNameHostingController: VectorHostingController
    private var onboardingDisplayNameViewModel: OnboardingDisplayNameViewModelProtocol
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((UserSession) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: OnboardingDisplayNameCoordinatorParameters) {
        self.parameters = parameters
        let viewModel = OnboardingDisplayNameViewModel.makeOnboardingDisplayNameViewModel(onboardingDisplayNameService: OnboardingDisplayNameService(userSession: parameters.userSession))
        let view = OnboardingDisplayNameScreen(viewModel: viewModel.context)
        onboardingDisplayNameViewModel = viewModel
        onboardingDisplayNameHostingController = VectorHostingController(rootView: view)
        onboardingDisplayNameHostingController.enableNavigationBarScrollEdgesAppearance = true
    }
    
    // MARK: - Public
    func start() {
        MXLog.debug("[OnboardingDisplayNameCoordinator] did start.")
        onboardingDisplayNameViewModel.completion = { [weak self] in
            guard let self = self else { return }
            MXLog.debug("[OnboardingDisplayNameCoordinator] OnboardingDisplayNameViewModel did complete.")
            self.completion?(self.parameters.userSession)
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.onboardingDisplayNameHostingController
    }
}
