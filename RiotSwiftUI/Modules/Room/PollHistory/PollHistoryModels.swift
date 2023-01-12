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

// MARK: - Coordinator

enum PollHistoryPromptType {
    case regular
    case upgrade
}

extension PollHistoryPromptType: Identifiable, CaseIterable {
    var id: Self { self }
    
    var title: String {
        switch self {
        case .regular:
            return VectorL10n.roomCreationMakePublicPromptTitle
        case .upgrade:
            return VectorL10n.roomDetailsHistorySectionPromptTitle
        }
    }
    
    var image: ImageAsset {
        switch self {
        case .regular:
            return Asset.Images.appSymbol
        case .upgrade:
            return Asset.Images.keyVerificationSuccessShield
        }
    }
}

// MARK: View model

enum PollHistoryViewModelResult {
    case accept
    case cancel
}

// MARK: View

struct PollHistoryViewState: BindableState {
    var promptType: PollHistoryPromptType
    var count: Int
}

enum PollHistoryViewAction {
    case incrementCount
    case decrementCount
    case accept
    case cancel
}
