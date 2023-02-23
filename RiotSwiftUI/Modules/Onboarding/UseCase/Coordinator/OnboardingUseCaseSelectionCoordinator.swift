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

final class OnboardingUseCaseSelectionCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private
    
    private let onboardingUseCaseHostingController: VectorHostingController
    private var onboardingUseCaseViewModel: OnboardingUseCaseViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((OnboardingUseCaseViewModelResult) -> Void)?
    
    // MARK: - Setup
    
    init() {
        let viewModel = OnboardingUseCaseViewModel()
        let view = OnboardingUseCaseSelectionScreen(viewModel: viewModel.context)
        onboardingUseCaseViewModel = viewModel
        
        onboardingUseCaseHostingController = VectorHostingController(rootView: view)
        onboardingUseCaseHostingController.vc_removeBackTitle()
        onboardingUseCaseHostingController.enableNavigationBarScrollEdgeAppearance = true
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: onboardingUseCaseHostingController)
    }
    
    // MARK: - Public

    func start() {
        MXLog.debug("[OnboardingUseCaseSelectionCoordinator] did start.")
        onboardingUseCaseViewModel.completion = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[OnboardingUseCaseSelectionCoordinator] OnboardingUseCaseViewModel did complete with result: \(result).")
            
            // Show a loading indicator which can be dismissed externally by calling `stop`.
            self.startLoading()
            self.completion?(result)
        }
    }
    
    func toPresentable() -> UIViewController {
        onboardingUseCaseHostingController
    }
    
    /// Stops any ongoing activities in the coordinator.
    func stop() {
        stopLoading()
    }
    
    // MARK: - Private
    
    /// Show an activity indicator whilst loading.
    private func startLoading() {
        loadingIndicator = indicatorPresenter.present(.loading(label: VectorL10n.loading, isInteractionBlocking: true))
    }
    
    /// Hide the currently displayed activity indicator.
    private func stopLoading() {
        loadingIndicator = nil
    }
}
