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

import SwiftUI
import CommonKit

struct UserSessionsOverviewCoordinatorParameters {
    let session: MXSession
}

final class UserSessionsOverviewCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: UserSessionsOverviewCoordinatorParameters
    private let userSessionsOverviewHostingController: UIViewController
    private var userSessionsOverviewViewModel: UserSessionsOverviewViewModelProtocol
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: (() -> Void)?
    
    // MARK: - Setup
    
    init(parameters: UserSessionsOverviewCoordinatorParameters) {
        self.parameters = parameters
        let viewModel = UserSessionsOverviewViewModel(userSessionsOverviewService: UserSessionsOverviewService())
        let view = UserSessionsOverview(viewModel: viewModel.context)
        userSessionsOverviewViewModel = viewModel
        userSessionsOverviewHostingController = VectorHostingController(rootView: view)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[UserSessionsOverviewCoordinator] did start.")
        userSessionsOverviewViewModel.completion = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[UserSessionsOverviewCoordinator] UserSessionsOverviewViewModel did complete with result: \(result).")
            switch result {
            case .done:
                self.completion?()
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.userSessionsOverviewHostingController
    }
}
