//
// Copyright 2023 New Vector Ltd
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

final class MockPollHistoryService: PollHistoryServiceProtocol {
    lazy var nextBatchPublishers: [AnyPublisher<TimelinePollDetails, Error>] = [
        (activePollsData + pastPollsData)
            .publisher
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    ]
    
    func nextBatch() -> AnyPublisher<TimelinePollDetails, Error> {
        nextBatchPublishers.isEmpty ? Empty().eraseToAnyPublisher() : nextBatchPublishers.removeFirst()
    }
    
    var updatesPublisher: AnyPublisher<TimelinePollDetails, Never> = Empty().eraseToAnyPublisher()
    var updates: AnyPublisher<TimelinePollDetails, Never> {
        updatesPublisher
    }
    
    var hasNextBatch = true
    
    var fetchedUpToPublisher: AnyPublisher<Date, Never> = Just(.init()).eraseToAnyPublisher()
    var fetchedUpTo: AnyPublisher<Date, Never> {
        fetchedUpToPublisher
    }
    
    var livePollsPublisher: AnyPublisher<TimelinePollDetails, Never> = Empty().eraseToAnyPublisher()
    var livePolls: AnyPublisher<TimelinePollDetails, Never> {
        livePollsPublisher
    }
}

private extension MockPollHistoryService {
    var activePollsData: [TimelinePollDetails] {
        (1...3)
            .map { index in
                TimelinePollDetails(id: "a\(index)",
                                    question: "Do you like the active poll number \(index)?",
                                    answerOptions: [],
                                    closed: false,
                                    startDate: .init().addingTimeInterval(TimeInterval(-index) * 3600 * 24),
                                    totalAnswerCount: 30,
                                    type: .disclosed,
                                    eventType: .started,
                                    maxAllowedSelections: 1,
                                    hasBeenEdited: false,
                                    hasDecryptionError: false)
            }
    }
    
    var pastPollsData: [TimelinePollDetails] {
        (1...3)
            .map { index in
                TimelinePollDetails(id: "p\(index)",
                                    question: "Do you like the active poll number \(index)?",
                                    answerOptions: [.init(id: "id", text: "Yes, of course!", count: 20, winner: true, selected: true)],
                                    closed: true,
                                    startDate: .init().addingTimeInterval(TimeInterval(-index) * 3600 * 24),
                                    totalAnswerCount: 30,
                                    type: .disclosed,
                                    eventType: .started,
                                    maxAllowedSelections: 1,
                                    hasBeenEdited: false,
                                    hasDecryptionError: false)
            }
    }
}
