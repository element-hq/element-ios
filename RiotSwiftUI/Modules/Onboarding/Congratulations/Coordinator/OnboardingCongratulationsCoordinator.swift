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

struct OnboardingCongratulationsCoordinatorParameters {
    /// The user session used to determine the user ID to display.
    let userSession: UserSession
    /// When `true` the "Personalise Profile" button will be hidden, preventing the
    /// user from setting a displayname or avatar.
    let personalizationDisabled: Bool
}

enum OnboardingCongratulationsCoordinatorResult {
    /// Show the display name and/or avatar screens for the user to personalize their profile.
    case personalizeProfile(UserSession)
    /// Continue the flow by skipping the display name and avatar screens.
    case takeMeHome(UserSession)
}

final class OnboardingCongratulationsCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: OnboardingCongratulationsCoordinatorParameters
    private let onboardingCongratulationsHostingController: VectorHostingController
    private var onboardingCongratulationsViewModel: OnboardingCongratulationsViewModelProtocol
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((OnboardingCongratulationsCoordinatorResult) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: OnboardingCongratulationsCoordinatorParameters) {
        self.parameters = parameters
        
        // TODO: Add confetti when personalizationDisabled is false
        let viewModel = OnboardingCongratulationsViewModel(userId: parameters.userSession.userId,
                                                           personalizationDisabled: parameters.personalizationDisabled)
        let view = OnboardingCongratulationsScreen(viewModel: viewModel.context)
        onboardingCongratulationsViewModel = viewModel
        onboardingCongratulationsHostingController = VectorHostingController(rootView: view)
        onboardingCongratulationsHostingController.statusBarStyle = .lightContent
    }
    
    // MARK: - Public
    func start() {
        MXLog.debug("[OnboardingCongratulationsCoordinator] did start.")
        onboardingCongratulationsViewModel.completion = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[OnboardingCongratulationsCoordinator] OnboardingCongratulationsViewModel did complete with result: \(result).")
            
            switch result {
            case .personalizeProfile:
                self.completion?(.personalizeProfile(self.parameters.userSession))
            case .takeMeHome:
                self.completion?(.takeMeHome(self.parameters.userSession))
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.onboardingCongratulationsHostingController
    }
}
