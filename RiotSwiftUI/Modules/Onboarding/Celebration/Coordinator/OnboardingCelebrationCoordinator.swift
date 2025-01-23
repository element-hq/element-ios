//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
        onboardingCelebrationHostingController.isNavigationBarHidden = true
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
        onboardingCelebrationHostingController
    }
}
