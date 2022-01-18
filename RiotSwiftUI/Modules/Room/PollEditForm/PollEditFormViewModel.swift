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

import SwiftUI
import Combine

struct PollEditFormViewModelParameters {
    let mode: PollEditFormMode
    let pollDetails: EditFormPollDetails
}

@available(iOS 14, *)
typealias PollEditFormViewModelType = StateStoreViewModel< PollEditFormViewState,
                                                           PollEditFormStateAction,
                                                           PollEditFormViewAction >
@available(iOS 14, *)
class PollEditFormViewModel: PollEditFormViewModelType {
    
    private struct Constants {
        static let minAnswerOptionsCount = 2
        static let maxAnswerOptionsCount = 20
        static let maxQuestionLength = 340
        static let maxAnswerOptionLength = 340
    }

    // MARK: - Properties

    // MARK: Private
    
    // MARK: Public
    
    var completion: ((PollEditFormViewModelResult) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: PollEditFormViewModelParameters) {
        let state = PollEditFormViewState(
            minAnswerOptionsCount: Constants.minAnswerOptionsCount,
            maxAnswerOptionsCount: Constants.maxAnswerOptionsCount,
            mode: parameters.mode,
            bindings: PollEditFormViewStateBindings(
                question: PollEditFormQuestion(text: parameters.pollDetails.question, maxLength: Constants.maxQuestionLength),
                answerOptions: parameters.pollDetails.answerOptions.map { PollEditFormAnswerOption(text: $0, maxLength: Constants.maxAnswerOptionLength) },
                type: parameters.pollDetails.type
            )
        )
        
        super.init(initialViewState: state)
    }
    
    // MARK: - Public
    
    override func process(viewAction: PollEditFormViewAction) {
        switch viewAction {
        case .cancel:
            completion?(.cancel)
        case .create:
            completion?(.create(buildPollDetails()))
        case .update:
            completion?(.update(buildPollDetails()))
        default:
            dispatch(action: .viewAction(viewAction))
        }
    }

    override class func reducer(state: inout PollEditFormViewState, action: PollEditFormStateAction) {
        switch action {
        case .viewAction(let viewAction):
            switch viewAction {
            case .deleteAnswerOption(let answerOption):
                state.bindings.answerOptions.removeAll { $0 == answerOption }
            case .addAnswerOption:
                state.bindings.answerOptions.append(PollEditFormAnswerOption(text: "", maxLength: Constants.maxAnswerOptionLength))
            default:
                break
            }
        case .startLoading:
            state.showLoadingIndicator = true
            break
        case .stopLoading(let error):
            state.showLoadingIndicator = false
            
            switch error {
            case .failedCreatingPoll:
                state.bindings.alertInfo = PollEditFormErrorAlertInfo(id: .failedCreatingPoll,
                                                                      title: VectorL10n.pollEditFormPostFailureTitle,
                                                                      subtitle: VectorL10n.pollEditFormPostFailureSubtitle)
            case .failedUpdatingPoll:
                state.bindings.alertInfo = PollEditFormErrorAlertInfo(id: .failedUpdatingPoll,
                                                                      title: VectorL10n.pollEditFormUpdateFailureTitle,
                                                                      subtitle: VectorL10n.pollEditFormUpdateFailureSubtitle)
            case .none:
                break
            }
            break
        }
    }
    
    // MARK: - Private
    
    private func buildPollDetails() -> EditFormPollDetails {
        return EditFormPollDetails(type: state.bindings.type,
                                   question: state.bindings.question.text.trimmingCharacters(in: .whitespacesAndNewlines),
                                   answerOptions: state.bindings.answerOptions.compactMap({ answerOption in
                                    let text = answerOption.text.trimmingCharacters(in: .whitespacesAndNewlines)
                                    return text.isEmpty ? nil : text
                                   }))
    }
}
