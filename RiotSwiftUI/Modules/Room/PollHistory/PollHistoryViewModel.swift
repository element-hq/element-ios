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

typealias PollHistoryViewModelType = StateStoreViewModel<PollHistoryViewState, PollHistoryViewAction>

final class PollHistoryViewModel: PollHistoryViewModelType, PollHistoryViewModelProtocol {
    private let pollService: PollHistoryServiceProtocol
    private var polls: [PollListData] = []
    private var fetchingTask: Task<Void, Error>? {
        didSet {
            oldValue?.cancel()
        }
    }
    
    var completion: ((PollHistoryViewModelResult) -> Void)?

    init(mode: PollHistoryMode, pollService: PollHistoryServiceProtocol) {
        self.pollService = pollService
        super.init(initialViewState: PollHistoryViewState(mode: mode))
    }

    // MARK: - Public

    override func process(viewAction: PollHistoryViewAction) {
        switch viewAction {
        case .viewAppeared:
            fetchingTask = fetchPolls()
        case .segmentDidChange:
            updatePolls()
        }
    }
}

private extension PollHistoryViewModel {
    func fetchPolls() -> Task<Void, Error> {
        Task {
            let polls = try await pollService.fetchHistory()
            
            guard Task.isCancelled == false else {
                return
            }
            
            await MainActor.run {
                self.polls = polls
                updatePolls()
            }
        }
    }
    
    func updatePolls() {
        let renderedPolls: [PollListData]
        
        switch context.mode {
        case .active:
            renderedPolls = polls.filter { $0.winningOption == nil }
        case .past:
            renderedPolls = polls.filter { $0.winningOption != nil }
        }
        
        state.polls = renderedPolls
    }
}
