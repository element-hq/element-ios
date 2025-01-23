//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

protocol CompletionSuggestionViewModelProtocol {
    /// Defines a shared context providing the ability to use a single `CompletionSuggestionViewModel` for multiple
    /// `CompletionSuggestionList` e.g. the list component can then be displayed seemlessly in both `RoomViewController`
    /// UIKit hosted context, and in Rich-Text-Editor's SwiftUI fullscreen mode, without need to reload the data.
    var sharedContext: CompletionSuggestionViewModelType.Context { get }
    var completion: ((CompletionSuggestionViewModelResult) -> Void)? { get set }
}
