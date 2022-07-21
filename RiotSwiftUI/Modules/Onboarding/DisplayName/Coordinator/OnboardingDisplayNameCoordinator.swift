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
import CommonKit

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
        return self.onboardingDisplayNameHostingController
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
