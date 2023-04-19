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

import Combine
import Foundation
import WysiwygComposer

protocol CompletionSuggestionUserItemProtocol: Avatarable {
    var userId: String { get }
    var displayName: String? { get }
    var avatarUrl: String? { get }
}

protocol CompletionSuggestionCommandItemProtocol {
    var name: String { get }
    var parametersFormat: String { get }
    var description: String { get }
}

enum CompletionSuggestionItem {
    case command(value: CompletionSuggestionCommandItemProtocol)
    case user(value: CompletionSuggestionUserItemProtocol)
}

protocol CompletionSuggestionServiceProtocol {
    var items: CurrentValueSubject<[CompletionSuggestionItem], Never> { get }
    
    var currentTextTrigger: String? { get }
    
    func processTextMessage(_ textMessage: String?)
    func processSuggestionPattern(_ suggestionPattern: SuggestionPattern?)
}

// MARK: Avatarable

extension CompletionSuggestionUserItemProtocol {
    var mxContentUri: String? {
        avatarUrl
    }

    var matrixItemId: String {
        userId
    }
}
