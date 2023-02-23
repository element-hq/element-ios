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
