//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
        onboardingCongratulationsHostingController.isNavigationBarHidden = true
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
        onboardingCongratulationsHostingController
    }
}
