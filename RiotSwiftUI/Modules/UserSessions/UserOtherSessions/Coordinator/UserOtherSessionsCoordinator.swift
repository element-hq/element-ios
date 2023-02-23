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

struct UserOtherSessionsCoordinatorParameters {
    let sessionInfos: [UserSessionInfo]
    let filter: UserOtherSessionsFilter
    let title: String
}

final class UserOtherSessionsCoordinator: Coordinator, Presentable {
    private let parameters: UserOtherSessionsCoordinatorParameters
    private let userOtherSessionsHostingController: UIViewController
    private var userOtherSessionsViewModel: UserOtherSessionsViewModelProtocol
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((UserOtherSessionsCoordinatorResult) -> Void)?
    
    init(parameters: UserOtherSessionsCoordinatorParameters) {
        self.parameters = parameters
        
        let viewModel = UserOtherSessionsViewModel(sessionInfos: parameters.sessionInfos,
                                                   filter: parameters.filter,
                                                   title: parameters.title,
                                                   settingsService: RiotSettings.shared)
        let view = UserOtherSessions(viewModel: viewModel.context)
        userOtherSessionsViewModel = viewModel
        userOtherSessionsHostingController = VectorHostingController(rootView: view)
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: userOtherSessionsHostingController)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[UserOtherSessionsCoordinator] did start.")
        userOtherSessionsViewModel.completion = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .showUserSessionOverview(sessionInfo: session):
                self.completion?(.openSessionOverview(sessionInfo: session))
            case let .logoutFromUserSessions(sessionInfos: sessionInfos):
                self.completion?(.logoutFromUserSessions(sessionInfos: sessionInfos))
            case .showSessionStateInfo(filter: let filter):
                self.completion?(.showSessionStateByFilter(filter: filter))
            }
            MXLog.debug("[UserOtherSessionsCoordinator] UserOtherSessionsViewModel did complete with result: \(result).")
        }
    }
    
    func toPresentable() -> UIViewController {
        userOtherSessionsHostingController
    }
    
    // MARK: - Private
}
