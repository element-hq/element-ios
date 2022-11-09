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
