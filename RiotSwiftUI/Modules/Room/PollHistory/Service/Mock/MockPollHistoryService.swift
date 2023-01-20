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
    private let polls: PassthroughSubject<TimelinePollDetails, Never> = .init()
    
    var pollHistory: AnyPublisher<TimelinePollDetails, Never> {
        polls.eraseToAnyPublisher()
    }
    
    var error: AnyPublisher<Error, Never> {
        Empty().eraseToAnyPublisher()
    }

    func next() {
        for poll in activePollsData + pastPollsData {
            polls.send(poll)
        }
    }
    
    var isFetching: AnyPublisher<Bool, Never> {
        Just(false).eraseToAnyPublisher()
    }

    var activePollsData: [TimelinePollDetails] = (1..<10)
        .map { index in
            TimelinePollDetails(id: "a\(index)",
                                question: "Do you like the active poll number \(index)?",
                                answerOptions: [],
                                closed: false,
                                startDate: .init(),
                                totalAnswerCount: 30,
                                type: .disclosed,
                                eventType: .started,
                                maxAllowedSelections: 1,
                                hasBeenEdited: false,
                                hasDecryptionError: false)
        }
    
    var pastPollsData: [TimelinePollDetails] = (1..<10)
        .map { index in
            TimelinePollDetails(id: "p\(index)",
                                question: "Do you like the active poll number \(index)?",
                                answerOptions: [.init(id: "id", text: "Yes, of course!", count: 20, winner: true, selected: true)],
                                closed: true,
                                startDate: .init(),
                                totalAnswerCount: 30,
                                type: .disclosed,
                                eventType: .started,
                                maxAllowedSelections: 1,
                                hasBeenEdited: false,
                                hasDecryptionError: false)
        }
}
