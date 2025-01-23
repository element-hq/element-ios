//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
            .environmentObject(AvatarViewModel(avatarService: AvatarService(mediaManager: parameters.session.mediaManager)))
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
