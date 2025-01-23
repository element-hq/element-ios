//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias PollHistoryViewModelType = StateStoreViewModel<PollHistoryViewState, PollHistoryViewAction>

final class PollHistoryViewModel: PollHistoryViewModelType, PollHistoryViewModelProtocol {
    private let pollService: PollHistoryServiceProtocol
    private var polls: [TimelinePollDetails]?
    private var subcriptions: Set<AnyCancellable> = .init()
    
    var completion: ((PollHistoryViewModelResult) -> Void)?

    init(mode: PollHistoryMode, pollService: PollHistoryServiceProtocol) {
        self.pollService = pollService
        super.init(initialViewState: PollHistoryViewState(mode: mode))
        state.canLoadMoreContent = pollService.hasNextBatch
    }

    // MARK: - Public

    override func process(viewAction: PollHistoryViewAction) {
        switch viewAction {
        case .viewAppeared:
            setupUpdateSubscriptions()
            fetchContent()
        case .segmentDidChange:
            updateViewState()
        case .showPollDetail(let poll):
            completion?(.showPollDetail(poll: poll))
        case .loadMoreContent:
            fetchContent()
        }
    }
}

private extension PollHistoryViewModel {
    func fetchContent() {
        state.isLoading = true
        
        pollService
            .nextBatch()
            .collect()
            .sink { [weak self] completion in
                self?.handleBatchEnded(completion: completion)
            } receiveValue: { [weak self] polls in
                self?.add(polls: polls)
            }
            .store(in: &subcriptions)
    }
    
    func handleBatchEnded(completion: Subscribers.Completion<Error>) {
        state.isLoading = false
        state.canLoadMoreContent = pollService.hasNextBatch
        
        switch completion {
        case .finished:
            break
        case .failure:
            polls = polls ?? []
            state.bindings.alertInfo = .init(id: true, title: VectorL10n.pollHistoryFetchingError)
        }
        
        updateViewState()
    }
    
    func setupUpdateSubscriptions() {
        subcriptions.removeAll()
        
        pollService
            .updates
            .sink { [weak self] detail in
                self?.update(poll: detail)
                self?.updateViewState()
            }
            .store(in: &subcriptions)
        
        pollService
            .fetchedUpTo
            .weakAssign(to: \.state.syncedUpTo, on: self)
            .store(in: &subcriptions)
        
        pollService
            .livePolls
            .sink { [weak self] livePoll in
                self?.add(polls: [livePoll])
                self?.updateViewState()
            }
            .store(in: &subcriptions)
    }
    
    func update(poll: TimelinePollDetails) {
        guard let pollIndex = polls?.firstIndex(where: { $0.id == poll.id }) else {
            return
        }
            
        polls?[pollIndex] = poll
    }
    
    func add(polls: [TimelinePollDetails]) {
        self.polls = (self.polls ?? []) + polls
    }
    
    func updateViewState() {
        let renderedPolls: [TimelinePollDetails]?
        
        switch context.mode {
        case .active:
            renderedPolls = polls?.filter { $0.closed == false }
        case .past:
            renderedPolls = polls?.filter { $0.closed == true }
        }
        
        state.polls = renderedPolls?.sorted(by: { $0.startDate > $1.startDate })
    }
}

extension PollHistoryViewModel.Context {
    var emptyPollsText: String {
        switch (viewState.bindings.mode, viewState.canLoadMoreContent) {
        case (.active, true):
            return VectorL10n.pollHistoryNoActivePollPeriodText("\(syncedPastDays)")
        case (.active, false):
            return VectorL10n.pollHistoryNoActivePollText
        case (.past, true):
            return VectorL10n.pollHistoryNoPastPollPeriodText("\(syncedPastDays)")
        case (.past, false):
            return VectorL10n.pollHistoryNoPastPollText
        }
    }
    
    var syncedPastDays: Int {
        guard let days = Calendar.current.dateComponents([.day], from: viewState.syncedUpTo, to: viewState.syncStartDate).day else {
            return 0
        }
        return max(0, days)
    }
}
