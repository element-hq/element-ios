// File created from SimpleUserProfileExample
// $ createScreen.sh Room/PollTimeline PollTimeline
/*
 Copyright 2021 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import SwiftUI
import MatrixSDK
import Combine

struct PollTimelineCoordinatorParameters {
    let session: MXSession
    let room: MXRoom
    let pollStartEvent: MXEvent
}

@available(iOS 14.0, *)
final class PollTimelineCoordinator: Coordinator, PollAggregatorDelegate {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: PollTimelineCoordinatorParameters
    private let selectedAnswerIdentifiersSubject = PassthroughSubject<[String], Never>()
    
    private var pollAggregator: PollAggregator
    private var pollTimelineViewModel: PollTimelineViewModel!
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    // MARK: - Setup
    
    @available(iOS 14.0, *)
    init(parameters: PollTimelineCoordinatorParameters) throws {
        self.parameters = parameters
        
        try pollAggregator = PollAggregator(session: parameters.session, room: parameters.room, pollStartEvent: parameters.pollStartEvent)
        pollAggregator.delegate = self
        
        pollTimelineViewModel = PollTimelineViewModel(timelinePoll: buildTimelinePollFrom(pollAggregator.poll))
        pollTimelineViewModel.callback = { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .selectedAnswerOptionsWithIdentifiers(let identifiers):
                self.selectedAnswerIdentifiersSubject.send(identifiers)
            }
        }
        
        selectedAnswerIdentifiersSubject
            .debounce(for: 1.0, scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] identifiers in
                guard let self = self else { return }

                self.parameters.room.sendPollResponse(for: parameters.pollStartEvent,
                                                      withAnswerIdentifiers: identifiers,
                                                      localEcho: nil, success: nil) { [weak self] error in
                    guard let self = self else { return }
                    
                    MXLog.error("[PollTimelineCoordinator]] Failed submitting response with error \(String(describing: error))")
                    
                    self.pollTimelineViewModel.dispatch(action: .showAnsweringFailure)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public
    func start() {
        
    }
    
    func toPresentable() -> UIViewController {
        return VectorHostingController(rootView: PollTimelineView(viewModel: pollTimelineViewModel.context))
    }
    
    func canEndPoll() -> Bool {
        return pollAggregator.poll.isClosed == false
    }
    
    func endPoll() {
        parameters.room.sendPollEnd(for: parameters.pollStartEvent, localEcho: nil, success: nil) { [weak self] error in
            self?.pollTimelineViewModel.dispatch(action: .showClosingFailure)
        }
    }
    
    // MARK: - PollAggregatorDelegate
    
    func pollAggregatorDidUpdateData(_ aggregator: PollAggregator) {
        pollTimelineViewModel.dispatch(action: .updateWithPoll(buildTimelinePollFrom(aggregator.poll)))
    }
    
    func pollAggregatorDidStartLoading(_ aggregator: PollAggregator) {
        
    }
    
    func pollAggregatorDidEndLoading(_ aggregator: PollAggregator) {
        
    }
    
    func pollAggregator(_ aggregator: PollAggregator, didFailWithError: Error) {
        
    }
    
    // MARK: - Private
    
    // PollProtocol is intentionally not available in the SwiftUI target as we don't want
    // to add the SDK as a dependency to it. We need to translate from one to the other on this level.
    func buildTimelinePollFrom(_ poll: PollProtocol) -> TimelinePoll {
        let answerOptions = poll.answerOptions.map { pollAnswerOption in
            TimelineAnswerOption(id: pollAnswerOption.id,
                                 text: pollAnswerOption.text,
                                 count: pollAnswerOption.count,
                                 winner: pollAnswerOption.isWinner,
                                 selected: pollAnswerOption.isCurrentUserSelection)
        }
        
        return TimelinePoll(question: poll.text,
                            answerOptions: answerOptions,
                            closed: poll.isClosed,
                            totalAnswerCount: poll.totalAnswerCount,
                            type: (poll.kind == .disclosed ? .disclosed : .undisclosed),
                            maxAllowedSelections: poll.maxAllowedSelections)
    }
}
