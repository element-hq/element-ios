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

protocol CompletionSuggestionViewModelProtocol {
    /// Defines a shared context providing the ability to use a single `CompletionSuggestionViewModel` for multiple
    /// `CompletionSuggestionList` e.g. the list component can then be displayed seemlessly in both `RoomViewController`
    /// UIKit hosted context, and in Rich-Text-Editor's SwiftUI fullscreen mode, without need to reload the data.
    var sharedContext: CompletionSuggestionViewModelType.Context { get }
    var completion: ((CompletionSuggestionViewModelResult) -> Void)? { get set }
}
