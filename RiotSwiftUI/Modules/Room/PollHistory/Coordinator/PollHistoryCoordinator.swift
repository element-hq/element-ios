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

struct PollHistoryCoordinatorParameters {
    let mode: PollHistoryMode
    let room: MXRoom
}

final class PollHistoryCoordinator: Coordinator, Presentable {
    private let parameters: PollHistoryCoordinatorParameters
    private let pollHistoryHostingController: UIViewController
    private var pollHistoryViewModel: PollHistoryViewModelProtocol
    
    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: (() -> Void)?
    
    init(parameters: PollHistoryCoordinatorParameters) {
        self.parameters = parameters
        let viewModel = PollHistoryViewModel(mode: parameters.mode, pollService: PollHistoryService(room: parameters.room, chunkSizeInDays: PollHistoryConstants.chunkSizeInDays))
        let view = PollHistory(viewModel: viewModel.context)
        pollHistoryViewModel = viewModel
        pollHistoryHostingController = VectorHostingController(rootView: view)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[PollHistoryCoordinator] did start.")
        pollHistoryViewModel.completion = { [weak self] result in
            self?.completion?()
        }
    }
    
    func toPresentable() -> UIViewController {
        pollHistoryHostingController
    }
}
