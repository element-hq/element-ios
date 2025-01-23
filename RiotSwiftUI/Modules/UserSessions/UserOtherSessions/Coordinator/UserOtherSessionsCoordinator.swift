//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CommonKit
import SwiftUI

struct UserOtherSessionsCoordinatorParameters {
    let sessionInfos: [UserSessionInfo]
    let filter: UserOtherSessionsFilter
    let title: String
    let showDeviceLogout: Bool
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
                                                   showDeviceLogout: parameters.showDeviceLogout,
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
