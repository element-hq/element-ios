//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

enum EditFormPollType {
    case disclosed
    case undisclosed
}

struct EditFormPollDetails {
    let type: EditFormPollType
    let question: String
    let answerOptions: [String]
    let maxSelections: UInt = 1
    
    static var `default`: EditFormPollDetails {
        EditFormPollDetails(type: .disclosed, question: "", answerOptions: ["", ""])
    }
}

enum PollEditFormMode {
    case creation
    case editing
}

enum PollEditFormViewAction {
    case addAnswerOption
    case deleteAnswerOption(PollEditFormAnswerOption)
    case cancel
    case create
    case update
}

enum PollEditFormViewModelResult {
    case cancel
    case create(EditFormPollDetails)
    case update(EditFormPollDetails)
}

struct PollEditFormQuestion {
    var text: String {
        didSet {
            text = String(text.prefix(maxLength))
        }
    }
    
    let maxLength: Int
}

struct PollEditFormAnswerOption: Identifiable, Equatable {
    let id = UUID()

    var text: String {
        didSet {
            text = String(text.prefix(maxLength))
        }
    }
    
    let maxLength: Int
}

struct PollEditFormViewState: BindableState {
    var minAnswerOptionsCount: Int
    var maxAnswerOptionsCount: Int
    var mode: PollEditFormMode
    var bindings: PollEditFormViewStateBindings
    
    var confirmationButtonEnabled: Bool {
        !bindings.question.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            bindings.answerOptions.filter { !$0.text.isEmpty }.count >= minAnswerOptionsCount
    }
    
    var addAnswerOptionButtonEnabled: Bool {
        bindings.answerOptions.count < maxAnswerOptionsCount
    }
    
    var showLoadingIndicator = false
}

struct PollEditFormViewStateBindings {
    var question: PollEditFormQuestion
    var answerOptions: [PollEditFormAnswerOption]
    var type: EditFormPollType
    
    var alertInfo: PollEditFormErrorAlertInfo?
}

struct PollEditFormErrorAlertInfo: Identifiable {
    enum AlertType {
        case failedCreatingPoll
        case failedUpdatingPoll
    }
    
    let id: AlertType
    let title: String
    let subtitle: String
}
