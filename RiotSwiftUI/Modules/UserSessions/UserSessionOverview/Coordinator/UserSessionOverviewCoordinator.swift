//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import CommonKit
import SwiftUI

struct UserSessionOverviewCoordinatorParameters {
    let session: MXSession
    let sessionInfo: UserSessionInfo
    let sessionsOverviewDataPublisher: CurrentValueSubject<UserSessionsOverviewData, Never>
}

final class UserSessionOverviewCoordinator: Coordinator, Presentable {
    private let parameters: UserSessionOverviewCoordinatorParameters
    private let hostingController: UIViewController
    private var viewModel: UserSessionOverviewViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((UserSessionOverviewCoordinatorResult) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: UserSessionOverviewCoordinatorParameters) {
        self.parameters = parameters

        let service = UserSessionOverviewService(session: parameters.session, sessionInfo: parameters.sessionInfo)
        viewModel = UserSessionOverviewViewModel(sessionInfo: parameters.sessionInfo,
                                                 service: service,
                                                 settingsService: RiotSettings.shared,
                                                 sessionsOverviewDataPublisher: parameters.sessionsOverviewDataPublisher)
        
        hostingController = VectorHostingController(rootView: UserSessionOverview(viewModel: viewModel.context))
        hostingController.vc_setLargeTitleDisplayMode(.never)
        hostingController.vc_removeBackTitle()
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: hostingController)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[UserSessionOverviewCoordinator] did start.")
        viewModel.completion = { [weak self] result in
            guard let self = self else { return }
            
            MXLog.debug("[UserSessionOverviewCoordinator] UserSessionOverviewViewModel did complete with result: \(result).")
            switch result {
            case let .verifySession(sessionInfo):
                self.completion?(.verifySession(sessionInfo))
            case let .showSessionDetails(sessionInfo: sessionInfo):
                self.completion?(.openSessionDetails(sessionInfo: sessionInfo))
            case let .renameSession(sessionInfo):
                self.completion?(.renameSession(sessionInfo))
            case let .logoutOfSession(sessionInfo):
                self.completion?(.logoutOfSession(sessionInfo))
            case let .showSessionStateInfo(sessionInfo):
                self.completion?(.showSessionStateInfo(sessionInfo))
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        hostingController
    }
    
    // MARK: - Private
}
