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

/// All Chats onboarding screen
final class AllChatsOnboardingCoordinator: NSObject, Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private
    
    private let hostingController: UIViewController
    private var viewModel: AllChatsOnboardingViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: (() -> Void)?
    
    // MARK: - Setup
    
    override init() {
        let viewModel = AllChatsOnboardingViewModel.makeAllChatsOnboardingViewModel()
        let view = AllChatsOnboarding(viewModel: viewModel.context)
        self.viewModel = viewModel
        hostingController = VectorHostingController(rootView: view)
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: hostingController)
        
        super.init()
        
        hostingController.presentationController?.delegate = self
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[AllChatsOnboardingCoordinator] did start.")
        viewModel.completion = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[AllChatsOnboardingCoordinator] AllChatsOnboardingViewModel did complete with result: \(result).")
            switch result {
            case .cancel:
                self.completion?()
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        hostingController
    }
    
    // MARK: - Private
    
    /// Show an activity indicator whilst loading.
    /// - Parameters:
    ///   - label: The label to show on the indicator.
    ///   - isInteractionBlocking: Whether the indicator should block any user interaction.
    private func startLoading(label: String = VectorL10n.loading, isInteractionBlocking: Bool = true) {
        loadingIndicator = indicatorPresenter.present(.loading(label: label, isInteractionBlocking: isInteractionBlocking))
    }
    
    /// Hide the currently displayed activity indicator.
    private func stopLoading() {
        loadingIndicator = nil
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension AllChatsOnboardingCoordinator: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        completion?()
    }
}
