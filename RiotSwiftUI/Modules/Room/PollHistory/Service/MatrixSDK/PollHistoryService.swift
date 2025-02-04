// 
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixSDK

final class PollHistoryService: PollHistoryServiceProtocol {
    private let room: MXRoom
    private let timeline: MXEventTimeline
    private let chunkSizeInDays: UInt
   
    private var timelineListener: Any?
    private var roomListener: Any?
    
    // polls aggregation
    private var pollAggregationContexts: [String: PollAggregationContext] = [:]
    
    // polls
    private var currentBatchSubject: PassthroughSubject<TimelinePollDetails, Error>?
    private var livePollsSubject: PassthroughSubject<TimelinePollDetails, Never> = .init()
    
    // polls updates
    private let updatesSubject: PassthroughSubject<TimelinePollDetails, Never> = .init()
   
    // timestamps
    private var targetTimestamp: Date = .init()
    private var oldestEventDateSubject: CurrentValueSubject<Date, Never> = .init(.init())
    
    var updates: AnyPublisher<TimelinePollDetails, Never> {
        updatesSubject.eraseToAnyPublisher()
    }
    
    init(room: MXRoom, chunkSizeInDays: UInt) {
        self.room = room
        self.chunkSizeInDays = chunkSizeInDays
        timeline = MXRoomEventTimeline(room: room, andInitialEventId: nil)
        setupTimeline()
        setupLiveUpdates()
    }
    
    func nextBatch() -> AnyPublisher<TimelinePollDetails, Error> {
        currentBatchSubject?.eraseToAnyPublisher() ?? startPagination()
    }
    
    var hasNextBatch: Bool {
        timeline.canPaginate(.backwards)
    }
    
    var fetchedUpTo: AnyPublisher<Date, Never> {
        oldestEventDateSubject.eraseToAnyPublisher()
    }
    
    var livePolls: AnyPublisher<TimelinePollDetails, Never> {
        livePollsSubject.eraseToAnyPublisher()
    }
    
    deinit {
        guard let roomListener = roomListener else {
            return
        }
        room.removeListener(roomListener)
    }
    
    class PollAggregationContext {
        var pollAggregator: PollAggregator?
        let isLivePoll: Bool
        var published: Bool
        
        init(pollAggregator: PollAggregator? = nil, isLivePoll: Bool, published: Bool = false) {
            self.pollAggregator = pollAggregator
            self.isLivePoll = isLivePoll
            self.published = published
        }
    }
}

private extension PollHistoryService {
    enum Constants {
        static let pageSize: UInt = 250
    }
    
    func setupTimeline() {
        timeline.resetPagination()
        
        timelineListener = timeline.listenToEvents { [weak self] event, _, _ in
            if event.eventType == .pollStart {
                self?.aggregatePoll(pollStartEvent: event, isLivePoll: false)
            }
           
            self?.updateTimestamp(event: event)
        }
    }
    
    func setupLiveUpdates() {
        roomListener = room.listen(toEventsOfTypes: [kMXEventTypeStringPollStart, kMXEventTypeStringPollStartMSC3381]) { [weak self] event, _, _ in
            if event.eventType == .pollStart {
                self?.aggregatePoll(pollStartEvent: event, isLivePoll: true)
            }
        }
    }
    
    func updateTimestamp(event: MXEvent) {
        oldestEventDate = min(event.originServerDate, oldestEventDate)
    }
    
    func startPagination() -> AnyPublisher<TimelinePollDetails, Error> {
        let startingTimestamp = oldestEventDate
        targetTimestamp = startingTimestamp.subtractingDays(chunkSizeInDays) ?? startingTimestamp
        
        let batchSubject = PassthroughSubject<TimelinePollDetails, Error>()
        currentBatchSubject = batchSubject
       
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.paginate()
        }
       
        return batchSubject.eraseToAnyPublisher()
    }
    
    func paginate() {
        timeline.paginate(Constants.pageSize, direction: .backwards, onlyFromStore: false) { [weak self] response in
            guard let self = self else {
                return
            }
            
            switch response {
            case .success:
                if self.timeline.canPaginate(.backwards), self.timestampTargetReached == false {
                    self.paginate()
                } else {
                    self.completeBatch(completion: .finished)
                }
            case .failure(let error):
                self.completeBatch(completion: .failure(error))
            }
        }
    }
    
    func completeBatch(completion: Subscribers.Completion<Error>) {
        currentBatchSubject?.send(completion: completion)
        currentBatchSubject = nil
    }
    
    func aggregatePoll(pollStartEvent: MXEvent, isLivePoll: Bool) {
        let eventId: String = pollStartEvent.eventId
        
        guard pollAggregationContexts[eventId] == nil else {
            return
        }
        
        let newContext: PollAggregationContext = .init(isLivePoll: isLivePoll)
        pollAggregationContexts[eventId] = newContext
        
        do {
            newContext.pollAggregator = try PollAggregator(session: room.mxSession, room: room, pollEvent: pollStartEvent, delegate: self)
        } catch {
            pollAggregationContexts.removeValue(forKey: eventId)
        }
    }
    
    var timestampTargetReached: Bool {
        oldestEventDate <= targetTimestamp
    }
    
    var oldestEventDate: Date {
        get {
            oldestEventDateSubject.value
        }
        set {
            oldestEventDateSubject.send(newValue)
        }
    }
}

private extension Date {
    func subtractingDays(_ days: UInt) -> Date? {
        Calendar.current.date(byAdding: DateComponents(day: -Int(days)), to: self)
    }
}

private extension MXEvent {
    var originServerDate: Date {
        .init(timeIntervalSince1970: Double(originServerTs) / 1000)
    }
}

// MARK: - PollAggregatorDelegate

extension PollHistoryService: PollAggregatorDelegate {
    func pollAggregatorDidStartLoading(_ aggregator: PollAggregator) { }
    
    func pollAggregator(_ aggregator: PollAggregator, didFailWithError: Error) { }
    
    func pollAggregatorDidEndLoading(_ aggregator: PollAggregator) {
        guard let poll = aggregator.poll, let context = pollAggregationContexts[poll.id], context.published == false else {
            return
        }
        
        context.published = true
        
        let newPoll: TimelinePollDetails = .init(poll: poll, represent: .started)
        
        if context.isLivePoll {
            livePollsSubject.send(newPoll)
        } else {
            currentBatchSubject?.send(newPoll)
        }
    }
    
    func pollAggregatorDidUpdateData(_ aggregator: PollAggregator) {
        guard let poll = aggregator.poll, let context = pollAggregationContexts[poll.id], context.published else {
            return
        }
        updatesSubject.send(.init(poll: poll, represent: .started))
    }
}
