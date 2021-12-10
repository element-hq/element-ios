// File created from SimpleUserProfileExample
// $ createScreen.sh Room/PollEditForm PollEditForm
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

enum PollEditFormStateAction {
    case viewAction(PollEditFormViewAction)
    case startLoading
    case stopLoading(Error?)
}

enum PollEditFormViewAction {
    case addAnswerOption
    case deleteAnswerOption(PollEditFormAnswerOption)
    case cancel
    case create
}

enum PollEditFormViewModelResult {
    case cancel
    case create(String, [String])
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
    var maxAnswerOptionsCount: Int
    var bindings: PollEditFormViewStateBindings
    
    var confirmationButtonEnabled: Bool {
        !bindings.question.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            bindings.answerOptions.filter({ !$0.text.isEmpty }).count >= 2
    }
    
    var addAnswerOptionButtonEnabled: Bool {
        bindings.answerOptions.count < maxAnswerOptionsCount
    }
    
    var showLoadingIndicator: Bool = false
}

struct PollEditFormViewStateBindings {
    var question: PollEditFormQuestion
    var answerOptions: [PollEditFormAnswerOption]
    
    var showsFailureAlert: Bool = false
}
