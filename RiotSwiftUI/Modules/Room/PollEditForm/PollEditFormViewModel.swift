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

import SwiftUI
import Combine

@available(iOS 14, *)
typealias PollEditFormViewModelType = StateStoreViewModel< PollEditFormViewState,
                                                           PollEditFormStateAction,
                                                           PollEditFormViewAction >
@available(iOS 14, *)
class PollEditFormViewModel: PollEditFormViewModelType {
    
    private struct Constants {
        static let maxAnswerOptionsCount = 20
        static let maxQuestionLength = 340
        static let maxAnswerOptionLength = 340
    }

    // MARK: - Properties

    // MARK: Private
    
    // MARK: Public
    
    var completion: ((PollEditFormViewModelResult) -> Void)?
    
    // MARK: - Setup
    
    init() {
        super.init(initialViewState: Self.defaultState())
    }
    
    private static func defaultState() -> PollEditFormViewState {
        return PollEditFormViewState(
            maxAnswerOptionsCount: Constants.maxAnswerOptionsCount,
            bindings: PollEditFormViewStateBindings(
                question: PollEditFormQuestion(text: "", maxLength: Constants.maxQuestionLength),
                answerOptions: [PollEditFormAnswerOption(text: "", maxLength: Constants.maxAnswerOptionLength),
                                PollEditFormAnswerOption(text: "", maxLength: Constants.maxAnswerOptionLength)
                ]
            )
        )
    }
    
    // MARK: - Public
    
    override func process(viewAction: PollEditFormViewAction) {
        switch viewAction {
        case .cancel:
            completion?(.cancel)
        case .create:
            completion?(.create(state.bindings.question.text.trimmingCharacters(in: .whitespacesAndNewlines),
                                state.bindings.answerOptions.compactMap({ answerOption in
                                    let text = answerOption.text.trimmingCharacters(in: .whitespacesAndNewlines)
                                    return text.isEmpty ? nil : text
                                })))
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
            
            if error != nil {
                state.bindings.showsFailureAlert = true
            }
            break
        }
    }
}
