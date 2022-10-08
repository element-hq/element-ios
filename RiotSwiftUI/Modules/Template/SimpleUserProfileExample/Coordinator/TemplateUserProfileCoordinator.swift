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

struct TemplateUserProfileCoordinatorParameters {
    let session: MXSession
}

final class TemplateUserProfileCoordinator: Coordinator, Presentable {
    private let parameters: TemplateUserProfileCoordinatorParameters
    private let templateUserProfileHostingController: UIViewController
    private var templateUserProfileViewModel: TemplateUserProfileViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: (() -> Void)?
    
    init(parameters: TemplateUserProfileCoordinatorParameters) {
        self.parameters = parameters
        let viewModel = TemplateUserProfileViewModel.makeTemplateUserProfileViewModel(templateUserProfileService: TemplateUserProfileService(session: parameters.session))
        let view = TemplateUserProfile(viewModel: viewModel.context)
            .addDependency(AvatarService.instantiate(mediaManager: parameters.session.mediaManager))
        templateUserProfileViewModel = viewModel
        templateUserProfileHostingController = VectorHostingController(rootView: view)
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: templateUserProfileHostingController)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[TemplateUserProfileCoordinator] did start.")
        templateUserProfileViewModel.completion = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[TemplateUserProfileCoordinator] TemplateUserProfileViewModel did complete with result: \(result).")
            switch result {
            case .cancel, .done:
                self.completion?()
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        templateUserProfileHostingController
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
