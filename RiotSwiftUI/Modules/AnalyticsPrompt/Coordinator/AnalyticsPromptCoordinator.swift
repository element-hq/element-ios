//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct AnalyticsPromptCoordinatorParameters {
    /// The session to use if analytics are enabled.
    let session: MXSession
}

final class AnalyticsPromptCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: AnalyticsPromptCoordinatorParameters
    private let analyticsPromptHostingController: VectorHostingController
    private var _analyticsPromptViewModel: Any?
    
    fileprivate var analyticsPromptViewModel: AnalyticsPromptViewModel {
        _analyticsPromptViewModel as! AnalyticsPromptViewModel
    }
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: (() -> Void)?
    
    // MARK: - Setup
    
    init(parameters: AnalyticsPromptCoordinatorParameters) {
        self.parameters = parameters
        
        let strings = AnalyticsPromptStrings()
        let promptType: AnalyticsPromptType
        
        if Analytics.shared.promptShouldDisplayUpgradeMessage {
            promptType = .upgrade
        } else {
            promptType = .newUser
        }
        
        let viewModel = AnalyticsPromptViewModel(promptType: promptType, strings: strings, termsURL: BuildSettings.analyticsConfiguration.termsURL)
        
        let view = AnalyticsPrompt(viewModel: viewModel.context)
        _analyticsPromptViewModel = viewModel
        analyticsPromptHostingController = VectorHostingController(rootView: view)
        analyticsPromptHostingController.isNavigationBarHidden = true
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[AnalyticsPromptCoordinator] did start.")
        
        analyticsPromptViewModel.completion = { [weak self] result in
            MXLog.debug("[AnalyticsPromptCoordinator] AnalyticsPromptViewModel did complete with result: \(result).")
            
            guard let self = self else { return }
            
            switch result {
            case .enable:
                Analytics.shared.optIn(with: self.parameters.session)
                self.completion?()
            case .disable:
                Analytics.shared.optOut()
                self.completion?()
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        analyticsPromptHostingController
    }
}
