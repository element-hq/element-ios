//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

typealias TimelinePollViewModelCallback = (TimelinePollViewModelResult) -> Void

enum TimelinePollViewAction {
    case selectAnswerOptionWithIdentifier(String)
}

enum TimelinePollViewModelResult {
    case selectedAnswerOptionsWithIdentifiers([String])
}

enum TimelinePollType {
    case disclosed
    case undisclosed
}

enum TimelinePollEventType {
    case started
    case ended
}

enum TimelinePollDetailsState {
    case loading
    case loaded(TimelinePollDetails)
    case errored
}

struct TimelinePollAnswerOption: Identifiable {
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

extension MutableCollection where Element == TimelinePollAnswerOption {
    mutating func updateEach(_ update: (inout Element) -> Void) {
        for index in indices {
            update(&self[index])
        }
    }
}

struct TimelinePollDetails {
    var id: String
    var question: String
    var answerOptions: [TimelinePollAnswerOption]
    var closed: Bool
    var startDate: Date
    var totalAnswerCount: UInt
    var type: TimelinePollType
    var eventType: TimelinePollEventType
    var maxAllowedSelections: UInt
    var hasBeenEdited: Bool
    var hasDecryptionError: Bool
    
    var hasCurrentUserVoted: Bool {
        answerOptions.contains(where: \.selected)
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

extension TimelinePollDetails: Identifiable { }

struct TimelinePollViewState: BindableState {
    var pollState: TimelinePollDetailsState
    var bindings: TimelinePollViewStateBindings
}

struct TimelinePollViewStateBindings {
    var alertInfo: AlertInfo<TimelinePollAlertType>?
}

enum TimelinePollAlertType {
    case failedClosingPoll
    case failedSubmittingAnswer
}
