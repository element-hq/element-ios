// 
// Copyright 2023 New Vector Ltd
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
import MatrixSDK

final class PollHistoryService: PollHistoryServiceProtocol {
    private let room: MXRoom
    private let timeline: MXEventTimeline
    private let chunkSizeInDays: UInt
    private let pollsSubject: PassthroughSubject<TimelinePollDetails, Never> = .init()
    private let errorSubject: PassthroughSubject<PollHistoryError, Never> = .init()
    private let isFetchingSubject: PassthroughSubject<Bool, Never> = .init()
    
    private var listner: Any?
    private var pollAggregators: [String: PollAggregator] = [:]
    private var targetTimestamp: Date
    private var oldestEventDate: Date = .distantFuture
    
    var pollHistory: AnyPublisher<TimelinePollDetails, Never> {
        pollsSubject.eraseToAnyPublisher()
    }
    
    var error: AnyPublisher<PollHistoryError, Never> {
        errorSubject.eraseToAnyPublisher()
    }
    
    var isFetching: AnyPublisher<Bool, Never> {
        isFetchingSubject.eraseToAnyPublisher()
    }
    
    init(room: MXRoom, chunkSizeInDays: UInt) {
        self.room = room
        self.chunkSizeInDays = chunkSizeInDays
        self.timeline = MXRoomEventTimeline(room: room, andInitialEventId: nil)
        targetTimestamp = Date().addingTimeInterval(-TimeInterval(chunkSizeInDays) * Constants.oneDayInSeconds)
        setup(timeline: timeline)
    }
    
    func next() {
        startPagination()
    }
}

private extension PollHistoryService {
    enum Constants {
        static let pageSize: UInt = 500
        static let oneDayInSeconds: TimeInterval = 8.6 * 10e3
    }
    
    func setup(timeline: MXEventTimeline) {
        listner = timeline.listenToEvents([MXEventType.pollStart, MXEventType.roomMessage, MXEventType.roomEncrypted]) { [weak self] event, _, _ in
            if event.eventType == .pollStart {
                self?.aggregatePoll(pollStartEvent: event)
            }
           
            self?.updateTimestamp(event: event)
        }
    }
    
    func updateTimestamp(event: MXEvent) {
        let eventDate = Date(timeIntervalSince1970: Double(event.originServerTs) / 1000)
        oldestEventDate = min(eventDate, oldestEventDate)
    }
    
    func startPagination() {
        isFetchingSubject.send(true)
        timeline.resetPagination()
        paginate(timeline: timeline)
    }
    
    func paginate(timeline: MXEventTimeline) {
        timeline.paginate(Constants.pageSize,
                          direction: .backwards,
                          onlyFromStore: false) { [weak self] response in
            
            guard let self = self else {
                return
            }
            
            switch response {
            case .success:
                if timeline.canPaginate(.backwards), self.timestampTargetReached == false {
                    self.paginate(timeline: timeline)
                } else {
                    self.isFetchingSubject.send(false)
                }
            case .failure(let error):
                self.errorSubject.send(.paginationFailed(error))
                self.isFetchingSubject.send(false)
            }
        }
    }
    
    func aggregatePoll(pollStartEvent: MXEvent) {
        guard pollAggregators[pollStartEvent.eventId] == nil else {
            return
        }
        
        guard let aggregator = try? PollAggregator(session: room.mxSession, room: room, pollEvent: pollStartEvent, delegate: self) else {
            return
        }
        
        pollAggregators[pollStartEvent.eventId] = aggregator
    }
    
    var timestampTargetReached: Bool {
        oldestEventDate <= targetTimestamp
    }
}

// MARK: - PollAggregatorDelegate

extension PollHistoryService: PollAggregatorDelegate {
    func pollAggregatorDidStartLoading(_ aggregator: PollAggregator) {}
    
    func pollAggregatorDidEndLoading(_ aggregator: PollAggregator) {
        pollsSubject.send(.init(poll: aggregator.poll, represent: .started))
    }
    
    func pollAggregator(_ aggregator: PollAggregator, didFailWithError: Error) {
        errorSubject.send(.pollAggregationFailed(didFailWithError))
    }
    
    func pollAggregatorDidUpdateData(_ aggregator: PollAggregator) {
        pollsSubject.send(.init(poll: aggregator.poll, represent: .started))
    }
}
