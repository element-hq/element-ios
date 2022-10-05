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
