//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CommonKit
import SwiftUI

struct OnboardingDisplayNameCoordinatorParameters {
    let userSession: UserSession
}

final class OnboardingDisplayNameCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: OnboardingDisplayNameCoordinatorParameters
    private let onboardingDisplayNameHostingController: VectorHostingController
    private var onboardingDisplayNameViewModel: OnboardingDisplayNameViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var waitingIndicator: UserIndicator?
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((UserSession) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: OnboardingDisplayNameCoordinatorParameters) {
        self.parameters = parameters
        
        // Don't pre-fill the display name from the MXID to encourage the user to enter something
        let viewModel = OnboardingDisplayNameViewModel(displayName: parameters.userSession.account.userDisplayName)
        
        let view = OnboardingDisplayNameScreen(viewModel: viewModel.context)
        onboardingDisplayNameViewModel = viewModel
        onboardingDisplayNameHostingController = VectorHostingController(rootView: view)
        onboardingDisplayNameHostingController.vc_removeBackTitle()
        onboardingDisplayNameHostingController.enableNavigationBarScrollEdgeAppearance = true
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: onboardingDisplayNameHostingController)
    }
    
    // MARK: - Public

    func start() {
        MXLog.debug("[OnboardingDisplayNameCoordinator] did start.")
        onboardingDisplayNameViewModel.completion = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[OnboardingDisplayNameCoordinator] OnboardingDisplayNameViewModel did complete.")
            
            switch result {
            case .save(let displayName):
                self.setDisplayName(displayName)
            case .skip:
                self.completion?(self.parameters.userSession)
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        onboardingDisplayNameHostingController
    }
    
    // MARK: - Private
    
    /// Show a blocking activity indicator whilst saving.
    private func startWaiting() {
        waitingIndicator = indicatorPresenter.present(.loading(label: VectorL10n.saving, isInteractionBlocking: true))
    }
    
    /// Hide the currently displayed activity indicator.
    private func stopWaiting() {
        waitingIndicator = nil
    }
    
    /// Set the supplied string as user's display name, completing the screen's display if successful.
    private func setDisplayName(_ displayName: String) {
        startWaiting()
        
        parameters.userSession.account.setUserDisplayName(displayName) { [weak self] in
            guard let self = self else { return }
            self.stopWaiting()
            self.completion?(self.parameters.userSession)
        } failure: { [weak self] error in
            guard let self = self else { return }
            self.stopWaiting()
            self.onboardingDisplayNameViewModel.processError(error as NSError?)
        }
    }
}
