//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CommonKit
import SwiftUI

struct UserSessionDetailsCoordinatorParameters {
    let sessionInfo: UserSessionInfo
}

final class UserSessionDetailsCoordinator: Coordinator, Presentable {
    private let parameters: UserSessionDetailsCoordinatorParameters
    private let userSessionDetailsHostingController: UIViewController
    private var userSessionDetailsViewModel: UserSessionDetailsViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((UserSessionDetailsViewModelResult) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: UserSessionDetailsCoordinatorParameters) {
        self.parameters = parameters
        
        let viewModel = UserSessionDetailsViewModel(sessionInfo: parameters.sessionInfo)
        let view = UserSessionDetails(viewModel: viewModel.context)
        userSessionDetailsViewModel = viewModel
        userSessionDetailsHostingController = VectorHostingController(rootView: view)
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: userSessionDetailsHostingController)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[UserSessionDetailsCoordinator] did start.")
        userSessionDetailsViewModel.completion = { [weak self] result in
            guard let self = self else {
                return
            }
            
            MXLog.debug("[UserSessionDetailsCoordinator] UserSessionDetailsViewModel did complete with result: \(result).")
            self.completion?(result)
        }
    }
    
    func toPresentable() -> UIViewController {
        userSessionDetailsHostingController
    }
}
