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

struct UserSessionOverviewCoordinatorParameters {
    let session: UserSessionInfo
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

        viewModel = UserSessionOverviewViewModel(session: parameters.session)
        
        hostingController = VectorHostingController(rootView: UserSessionOverview(viewModel: viewModel.context))
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: hostingController)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[UserSessionOverviewCoordinator] did start.")
        viewModel.completion = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[UserSessionOverviewCoordinator] UserSessionOverviewViewModel did complete with result: \(result).")
            switch result {
            case .verifyCurrentSession:
                break // TODO:
            case let .showSessionDetails(session: session):
                self.completion?(.openSessionDetails(session: session))
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        hostingController
    }
    
    // MARK: - Private
}
