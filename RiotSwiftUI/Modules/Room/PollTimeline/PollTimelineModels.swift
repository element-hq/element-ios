// File created from SimpleUserProfileExample
// $ createScreen.sh Room/PollTimeline PollTimeline
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
import SwiftUI

typealias PollTimelineViewModelCallback = ((PollTimelineViewModelResult) -> Void)

enum PollTimelineStateAction {
    case viewAction(PollTimelineViewAction, PollTimelineViewModelCallback?)
    case updateWithPoll(TimelinePoll)
    case showAnsweringFailure
    case showClosingFailure
}

enum PollTimelineViewAction {
    case selectAnswerOptionWithIdentifier(String)
}

enum PollTimelineViewModelResult {
    case selectedAnswerOptionsWithIdentifiers([String])
}

enum TimelinePollType {
    case disclosed
    case undisclosed
}

class TimelineAnswerOption: Identifiable {
    var id: String
    var text: String
    var count: UInt
    var winner: Bool
    var selected: Bool
    
    init(id: String, text: String, count: UInt, winner: Bool, selected: Bool) {
        self.id = id
        self.text = text
        self.count = count
        self.winner = winner
        self.selected = selected
    }
}

class TimelinePoll {
    var question: String
    var answerOptions: [TimelineAnswerOption]
    var closed: Bool
    var totalAnswerCount: UInt
    var type: TimelinePollType
    var maxAllowedSelections: UInt
    var hasBeenEdited: Bool = true
    
    init(question: String, answerOptions: [TimelineAnswerOption],
         closed: Bool,
         totalAnswerCount: UInt,
         type: TimelinePollType,
         maxAllowedSelections: UInt, hasBeenEdited: Bool) {
        self.question = question
        self.answerOptions = answerOptions
        self.closed = closed
        self.totalAnswerCount = totalAnswerCount
        self.type = type
        self.maxAllowedSelections = maxAllowedSelections
        self.hasBeenEdited = hasBeenEdited
    }
    
    var hasCurrentUserVoted: Bool {
        answerOptions.filter { $0.selected == true}.count > 0
    }
}

struct PollTimelineViewState: BindableState {
    var poll: TimelinePoll
    var bindings: PollTimelineViewStateBindings
}

struct PollTimelineViewStateBindings {
    var alertInfo: PollTimelineErrorAlertInfo?
}

struct PollTimelineErrorAlertInfo: Identifiable {
    enum AlertType {
        case failedClosingPoll
        case failedSubmittingAnswer
    }
    
    let id: AlertType
    let title: String
    let subtitle: String
}
