//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CommonKit
import MatrixSDK
import SwiftUI

struct PollHistoryCoordinatorParameters {
    let mode: PollHistoryMode
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
    var completion: ((MXEvent) -> Void)?
    
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
        guard let event = parameters.room.mxSession.store.event(withEventId: poll.id, inRoom: parameters.room.roomId),
              let detailCoordinator: PollHistoryDetailCoordinator = try? .init(parameters: .init(event: event, poll: poll, room: parameters.room)) else {
            pollHistoryViewModel.context.alertInfo = .init(id: true, title: VectorL10n.settingsDiscoveryErrorMessage)
            return
        }
        detailCoordinator.toPresentable().presentationController?.delegate = self
        detailCoordinator.completion = { [weak self, weak detailCoordinator, weak event] result in
            guard let self, let coordinator = detailCoordinator, let event = event else { return }
            self.handlePollDetailResult(result, coordinator: coordinator, event: event, poll: poll)
        }
        
        add(childCoordinator: detailCoordinator)
        detailCoordinator.start()
        toPresentable().present(detailCoordinator.toPresentable(), animated: true)
    }
    
    func toPresentable() -> UIViewController {
        pollHistoryHostingController
    }
    
    private func handlePollDetailResult(_ result: PollHistoryDetailViewModelResult, coordinator: Coordinator, event: MXEvent, poll: TimelinePollDetails) {
        switch result {
        case .dismiss:
            toPresentable().dismiss(animated: true)
            remove(childCoordinator: coordinator)
        case .viewInTimeline:
            toPresentable().dismiss(animated: false)
            remove(childCoordinator: coordinator)
            var event = event
            if poll.closed {
                let room = parameters.room
                let relatedEvents = room.mxSession.store.relations(forEvent: event.eventId, inRoom: room.roomId, relationType: MXEventRelationTypeReference)
                let pollEndedEvent = relatedEvents.first(where: { $0.eventType == .pollEnd })
                event = pollEndedEvent ?? event
            }
            completion?(event)
        }
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
