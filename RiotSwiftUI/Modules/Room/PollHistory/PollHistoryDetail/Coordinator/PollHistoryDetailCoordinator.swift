//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
