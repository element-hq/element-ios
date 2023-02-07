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
import MatrixSDK
import SwiftUI

struct PollHistoryDetailCoordinatorParameters {
    let event: MXEvent
    let poll: TimelinePollDetails
    let room: MXRoom
}

final class PollHistoryDetailCoordinator: Coordinator, Presentable {
    private let parameters: PollHistoryDetailCoordinatorParameters
    private let pollHistoryDetailHostingController: UIViewController
    private var pollHistoryDetailViewModel: PollHistoryDetailViewModelProtocol

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((PollHistoryDetailViewModelResult) -> Void)?
    
    init(parameters: PollHistoryDetailCoordinatorParameters) throws {
        self.parameters = parameters
        let timelinePollCoordinator = try TimelinePollCoordinator(parameters: .init(session: parameters.room.mxSession, room: parameters.room, pollEvent: parameters.event))
        
        let viewModel = PollHistoryDetailViewModel(poll: parameters.poll)
        let view = PollHistoryDetail(viewModel: viewModel.context, contentPoll: timelinePollCoordinator.toView())
        pollHistoryDetailViewModel = viewModel
        pollHistoryDetailHostingController = VectorHostingController(rootView: view)
        add(childCoordinator: timelinePollCoordinator)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[PollHistoryDetailCoordinator] did start.")
        pollHistoryDetailViewModel.completion = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .dismiss:
                self.completion?(.dismiss)
            case .viewInTimeline:
                self.completion?(.viewInTimeline)
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        pollHistoryDetailHostingController
    }
}
