//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
