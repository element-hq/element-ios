//
// Copyright 2022 New Vector Ltd
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

struct UserSessionsOverviewCoordinatorParameters {
    let session: MXSession
}

final class UserSessionsOverviewCoordinator: Coordinator, Presentable {
    private let parameters: UserSessionsOverviewCoordinatorParameters
    private let hostingViewController: UIViewController
    private var viewModel: UserSessionsOverviewViewModelProtocol
    private let service: UserSessionsOverviewService

    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    
    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((UserSessionsOverviewCoordinatorResult) -> Void)?

    init(parameters: UserSessionsOverviewCoordinatorParameters) {
        self.parameters = parameters
        
        service = UserSessionsOverviewService(mxSession: parameters.session)
        viewModel = UserSessionsOverviewViewModel(userSessionsOverviewService: service)
        hostingViewController = VectorHostingController(rootView: UserSessionsOverview(viewModel: viewModel.context))
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: hostingViewController)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[UserSessionsOverviewCoordinator] did start.")
        viewModel.completion = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[UserSessionsOverviewCoordinator] UserSessionsOverviewViewModel did complete with result: \(result).")
            
            switch result {
            case let .showOtherSessions(sessions: sessions, filter: filter):
                self.showOtherSessions(sessions: sessions, filterBy: filter)
            case .verifyCurrentSession:
                self.startVerifyCurrentSession()
            case let .showCurrentSessionOverview(session):
                self.showCurrentSessionOverview(session: session)
            case let .showUserSessionOverview(session):
                self.showUserSessionOverview(session: session)
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        hostingViewController
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
    
    private func showOtherSessions(sessions: [UserSessionInfo], filterBy filter: OtherUserSessionsFilter) {
        completion?(.openOtherSessions(sessions: sessions, filter: filter))
    }
    
    private func startVerifyCurrentSession() {
        // TODO:openSessionOverview
    }
    
    private func showCurrentSessionOverview(session: UserSessionInfo) {
        completion?(.openSessionOverview(session: session))
    }
    
    private func showUserSessionOverview(session: UserSessionInfo) {
        completion?(.openSessionOverview(session: session))
    }

}
