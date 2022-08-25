// File created from ScreenTemplate
// $ createScreen.sh ReactionHistory ReactionHistory
/*
 Copyright 2019 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation

final class ReactionHistoryViewModel: ReactionHistoryViewModelType {
    // MARK: - Constants
    
    private enum Pagination {
        static let count: UInt = 30
    }
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let roomId: String
    private let eventId: String
    private let aggregations: MXAggregations
    private let eventFormatter: MXKEventFormatter
    private let reactionsFormattingQueue: DispatchQueue
    
    private var reactionHistoryViewDataList: [ReactionHistoryViewData] = []
    private var operation: MXHTTPOperation?
    private var nextBatch: String?
    private var viewState: ReactionHistoryViewState?
    
    private lazy var roomMembers: MXRoomMembers? = buildRoomMembers()
    
    // MARK: Public

    weak var viewDelegate: ReactionHistoryViewModelViewDelegate?
    weak var coordinatorDelegate: ReactionHistoryViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, roomId: String, eventId: String) {
        self.session = session
        aggregations = session.aggregations
        self.roomId = roomId
        self.eventId = eventId
        eventFormatter = EventFormatter(matrixSession: session)
        reactionsFormattingQueue = DispatchQueue(label: "\(type(of: self)).reactionsFormattingQueue")
    }
    
    // MARK: - Public
    
    func process(viewAction: ReactionHistoryViewAction) {
        switch viewAction {
        case .loadMore:
            loadMoreHistory()
        case .close:
            coordinatorDelegate?.reactionHistoryViewModelDidClose(self)
        }
    }
    
    // MARK: - Private
    
    private func canLoadMoreHistory() -> Bool {
        guard let viewState = viewState else {
            return true
        }
        
        let canLoadMoreHistory: Bool
        
        switch viewState {
        case .loading:
            canLoadMoreHistory = false
        case .loaded(reactionHistoryViewDataList: _, allDataLoaded: let allDataLoaded):
            canLoadMoreHistory = !allDataLoaded
        default:
            canLoadMoreHistory = true
        }
        
        return canLoadMoreHistory
    }
    
    private func loadMoreHistory() {
        guard canLoadMoreHistory() else {
            MXLog.debug("[ReactionHistoryViewModel] loadMoreHistory: pending loading or all data loaded")
            return
        }
        
        guard operation == nil else {
            MXLog.debug("[ReactionHistoryViewModel] loadMoreHistory: operation already pending")
            return
        }
        
        update(viewState: .loading)
        
        operation = aggregations.reactionsEvents(forEvent: eventId, inRoom: roomId, from: nextBatch, limit: Int(Pagination.count), success: { [weak self] response in
            guard let self = self else {
                return
            }
            
            self.nextBatch = response.nextBatch
            self.operation = nil
            
            self.process(reactionEvents: response.chunk, nextBatch: response.nextBatch)
            
        }, failure: { [weak self] error in
            guard let self = self else {
                return
            }
            
            self.operation = nil
            self.update(viewState: .error(error))
        })
    }
    
    private func process(reactionEvents: [MXEvent], nextBatch: String?) {
        reactionsFormattingQueue.async {
            let reactionHistoryList = reactionEvents.compactMap { reactionEvent -> ReactionHistoryViewData? in
                self.reactionHistoryViewData(from: reactionEvent)
            }
            
            self.reactionHistoryViewDataList.append(contentsOf: reactionHistoryList)
            
            let allDataLoaded = nextBatch == nil
            
            DispatchQueue.main.async {
                self.update(viewState: .loaded(reactionHistoryViewDataList: self.reactionHistoryViewDataList, allDataLoaded: allDataLoaded))
            }
        }
    }
    
    private func reactionHistoryViewData(from reactionEvent: MXEvent) -> ReactionHistoryViewData? {
        guard let userId = reactionEvent.sender,
              let reaction = reactionEvent.relatesTo?.key,
              let reactionDateString = eventFormatter.dateString(fromTimestamp: reactionEvent.originServerTs, withTime: true) else {
            return nil
        }
        
        let userDisplayName = userDisplayName(from: userId) ?? userId
        
        return ReactionHistoryViewData(reaction: reaction, userDisplayName: userDisplayName, dateString: reactionDateString)
    }
    
    private func userDisplayName(from userId: String) -> String? {
        guard let roomMembers = roomMembers else {
            return nil
        }
        let roomMember = roomMembers.member(withUserId: userId)
        return roomMember?.displayname
    }
    
    private func buildRoomMembers() -> MXRoomMembers? {
        guard let room = session.room(withRoomId: roomId) else {
            return nil
        }
        return room.dangerousSyncState?.members
    }
    
    private func update(viewState: ReactionHistoryViewState) {
        self.viewState = viewState
        viewDelegate?.reactionHistoryViewModel(self, didUpdateViewState: viewState)
    }
}
