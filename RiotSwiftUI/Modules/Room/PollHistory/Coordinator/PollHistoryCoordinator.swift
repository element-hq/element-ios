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
import MatrixSDK
import SwiftUI

struct PollHistoryCoordinatorParameters {
    let mode: PollHistoryMode
    let session: MXSession
    let room: MXRoom
    let navigationRouter: NavigationRouterType
}

final class PollHistoryCoordinator: NSObject, Coordinator, Presentable {
    private let parameters: PollHistoryCoordinatorParameters
    private let pollHistoryHostingController: UIViewController
    private var pollHistoryViewModel: PollHistoryViewModelProtocol
    private let navigationRouter: NavigationRouterType
    
    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: (() -> Void)?
    
    init(parameters: PollHistoryCoordinatorParameters) {
        self.parameters = parameters
        let viewModel = PollHistoryViewModel(mode: parameters.mode, pollService: PollHistoryService(room: parameters.room, chunkSizeInDays: PollHistoryConstants.chunkSizeInDays))
        let view = PollHistory(viewModel: viewModel.context)
        pollHistoryViewModel = viewModel
        pollHistoryHostingController = VectorHostingController(rootView: view)
        navigationRouter = parameters.navigationRouter
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[PollHistoryCoordinator] did start.")
        pollHistoryViewModel.completion = { [weak self] result in
            switch result {
            case .showPollDetail(let poll):
                self?.showPollDetail(poll)
            }
        }
    }
    
    func showPollDetail(_ poll: TimelinePollDetails) {
        
        parameters.session.event(withEventId: poll.id, inRoom: parameters.room.roomId) { [weak self] response in
            guard let self else { return }
            if let event = response.value,
               let detailCoordinator: PollHistoryDetailCoordinator = try? .init(parameters: .init(pollHistoryDetails: MockPollHistoryDetailScreenState.openUndisclosed.poll, event: event, session: self.parameters.session, room: self.parameters.room)) {
                detailCoordinator.toPresentable().presentationController?.delegate = self
                detailCoordinator.completion = { [weak self, weak detailCoordinator] result in
                    guard let self = self, let coordinator = detailCoordinator else { return }
                    switch result {
                    case .dismiss:
                        self.toPresentable().dismiss(animated: true)
                        self.remove(childCoordinator: coordinator)
                    case .viewInTimeline:
                        self.toPresentable().dismiss(animated: true)
                        self.remove(childCoordinator: coordinator)
                        // TODO: go back in timeline
                    }
                }
                
                self.add(childCoordinator: detailCoordinator)
                detailCoordinator.start()
                self.toPresentable().present(detailCoordinator.toPresentable(), animated: true)
            } else {
                // TODO: manage error
            }
        }
        

    }
    
    func toPresentable() -> UIViewController {
        pollHistoryHostingController
    }
}

// MARK: UIAdaptivePresentationControllerDelegate

extension PollHistoryCoordinator: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        guard let coordinator = childCoordinators.last else {
            return
        }
        remove(childCoordinator: coordinator)
    }
}
