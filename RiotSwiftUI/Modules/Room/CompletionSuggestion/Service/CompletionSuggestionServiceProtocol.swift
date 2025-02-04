//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
