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

import Foundation

// MARK: - Coordinator

typealias PollHistoryDetailViewModelCallback = (PollHistoryDetailViewModelResult) -> Void

enum PollHistoryDetailViewModelResult {
    case selectedAnswerOptionsWithIdentifiers([String])
    case dismiss
}

// MARK: View model

struct PollHistoryDetails {
    
    public static let dummy: PollHistoryDetails = MockPollHistoryDetailScreenState.openUndisclosed.poll
    
    var question: String
    var answerOptions: [TimelinePollAnswerOption]
    var closed: Bool
    var totalAnswerCount: UInt
    var type: TimelinePollType
    var eventType: TimelinePollEventType
    var maxAllowedSelections: UInt
    var hasBeenEdited = true
    var hasDecryptionError: Bool
    
    init(question: String, answerOptions: [TimelinePollAnswerOption],
         closed: Bool,
         totalAnswerCount: UInt,
         type: TimelinePollType,
         eventType: TimelinePollEventType,
         maxAllowedSelections: UInt,
         hasBeenEdited: Bool,
         hasDecryptionError: Bool) {
        self.question = question
        self.answerOptions = answerOptions
        self.closed = closed
        self.totalAnswerCount = totalAnswerCount
        self.type = type
        self.eventType = eventType
        self.maxAllowedSelections = maxAllowedSelections
        self.hasBeenEdited = hasBeenEdited
        self.hasDecryptionError = hasDecryptionError
    }
    
    var hasCurrentUserVoted: Bool {
        answerOptions.filter { $0.selected == true }.count > 0
    }
    
    var shouldDiscloseResults: Bool {
        if closed {
            return totalAnswerCount > 0
        } else {
            return type == .disclosed && totalAnswerCount > 0 && hasCurrentUserVoted
        }
    }
    
    var representsPollEndedEvent: Bool {
        eventType == .ended
    }
}

// MARK: View

struct PollHistoryDetailViewState: BindableState {
    var poll: PollHistoryDetails
}

enum PollHistoryDetailViewAction {
    case selectAnswerOptionWithIdentifier(String)
}
