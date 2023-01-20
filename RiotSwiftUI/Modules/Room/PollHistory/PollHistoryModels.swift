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

// MARK: View model

enum PollHistoryViewModelResult: Equatable {
    #warning("e.g. show poll detail")
}

// MARK: View

enum PollHistoryMode: CaseIterable {
    case active
    case past
}

enum PollHistoryLoadingState {
    case idle
    case loading(firstLoad: Bool)
}

extension PollHistoryLoadingState {
    var isLoadingOnLanding: Bool {
        switch self {
        case .idle:
            return false
        case .loading(let firstLoad):
            return firstLoad
        }
    }
    
    var isLoading: Bool {
        switch self {
        case .idle:
            return false
        case .loading:
            return true
        }
    }
}

struct PollHistoryViewBindings {
    var mode: PollHistoryMode
}

struct PollHistoryViewState: BindableState {
    init(mode: PollHistoryMode, loadingState: PollHistoryLoadingState) {
        bindings = .init(mode: mode)
        self.loadingState = loadingState
    }
    
    var bindings: PollHistoryViewBindings
    var loadingState: PollHistoryLoadingState
    var polls: [TimelinePollDetails] = []
}

enum PollHistoryViewAction {
    case viewAppeared
    case segmentDidChange
}
