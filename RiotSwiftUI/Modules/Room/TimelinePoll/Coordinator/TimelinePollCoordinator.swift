//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import MatrixSDK
import SwiftUI

struct TimelinePollCoordinatorParameters {
    let session: MXSession
    let room: MXRoom
    let pollEvent: MXEvent
}

final class TimelinePollCoordinator: Coordinator, Presentable, PollAggregatorDelegate {
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: TimelinePollCoordinatorParameters
    private let selectedAnswerIdentifiersSubject = PassthroughSubject<[String], Never>()
    
    private var pollAggregator: PollAggregator!
    private(set) var viewModel: TimelinePollViewModelProtocol!
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    // MARK: - Setup
    
    init(parameters: TimelinePollCoordinatorParameters) throws {
        self.parameters = parameters
        
        viewModel = TimelinePollViewModel(timelinePollDetailsState: .loading)
        try pollAggregator = PollAggregator(session: parameters.session, room: parameters.room, pollEvent: parameters.pollEvent, delegate: self)
        
        viewModel.completion = { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .selectedAnswerOptionsWithIdentifiers(let identifiers):
                self.selectedAnswerIdentifiersSubject.send(identifiers)
            }
        }
        
        selectedAnswerIdentifiersSubject
            .debounce(for: 2.0, scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] identifiers in
                guard let self = self else { return }

                self.parameters.room.sendPollResponse(for: parameters.pollEvent,
                                                      withAnswerIdentifiers: identifiers,
                                                      threadId: nil,
                                                      localEcho: nil, success: nil) { [weak self] error in
                    guard let self = self else { return }
                    
                    MXLog.error("[TimelinePollCoordinator]] Failed submitting response", context: error)
                    
                    self.viewModel.showAnsweringFailure()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public

    func start() { }
    
    func toPresentable() -> UIViewController {
        VectorHostingController(rootView: TimelinePollView(viewModel: viewModel.context))
    }

    func toView() -> any View {
        TimelinePollView(viewModel: viewModel.context)
    }
    
    func canEndPoll() -> Bool {
        pollAggregator.poll?.isClosed == false
    }
    
    func canEditPoll() -> Bool {
        pollAggregator.poll?.isClosed == false && pollAggregator.poll?.totalAnswerCount == 0
    }
    
    func endPoll() {
        parameters.room.sendPollEnd(for: parameters.pollEvent, threadId: nil, localEcho: nil, success: nil) { [weak self] _ in
            self?.viewModel.showClosingFailure()
        }
    }
    
    // MARK: - PollAggregatorDelegate
    
    func pollAggregatorDidUpdateData(_ aggregator: PollAggregator) {
        if let poll = aggregator.poll {
            viewModel.updateWithPollDetailsState(.loaded(buildTimelinePollFrom(poll)))
        }
    }
    
    func pollAggregatorDidStartLoading(_ aggregator: PollAggregator) { }
    
    func pollAggregatorDidEndLoading(_ aggregator: PollAggregator) {
        guard let poll = aggregator.poll else {
            return
        }
        viewModel.updateWithPollDetailsState(.loaded(buildTimelinePollFrom(poll)))
    }
    
    func pollAggregator(_ aggregator: PollAggregator, didFailWithError: Error) {
        viewModel.updateWithPollDetailsState(.errored)
    }
    
    // MARK: - Private

    func buildTimelinePollFrom(_ poll: PollProtocol) -> TimelinePollDetails {
        let representedType: TimelinePollEventType = parameters.pollEvent.eventType == .pollStart ? .started : .ended
        return .init(poll: poll, represent: representedType)
    }
}

// PollProtocol is intentionally not available in the SwiftUI target as we don't want
// to add the SDK as a dependency to it. We need to translate from one to the other on this level.
extension TimelinePollDetails {
    init(poll: PollProtocol, represent eventType: TimelinePollEventType) {
        let answerOptions = poll.answerOptions.map { pollAnswerOption in
            TimelinePollAnswerOption(id: pollAnswerOption.id,
                                     text: pollAnswerOption.text,
                                     count: pollAnswerOption.count,
                                     winner: pollAnswerOption.isWinner,
                                     selected: pollAnswerOption.isCurrentUserSelection)
        }
        
        self.init(id: poll.id,
                  question: poll.text,
                  answerOptions: answerOptions,
                  closed: poll.isClosed,
                  startDate: poll.startDate,
                  totalAnswerCount: poll.totalAnswerCount,
                  type: poll.kind.timelinePollType,
                  eventType: eventType,
                  maxAllowedSelections: poll.maxAllowedSelections,
                  hasBeenEdited: poll.hasBeenEdited,
                  hasDecryptionError: poll.hasDecryptionError)
    }
}

private extension PollKind {
    var timelinePollType: TimelinePollType {
        switch self {
        case .disclosed:
            return .disclosed
        case .undisclosed:
            return .undisclosed
        }
    }
}
