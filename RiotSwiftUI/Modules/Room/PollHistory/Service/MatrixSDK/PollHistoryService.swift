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
    private var timelineListener: Any?
   
    private let updatesSubject: PassthroughSubject<TimelinePollDetails, Never> = .init()
    private let pollErrorsSubject: PassthroughSubject<Error, Never> = .init()
    
    private var pollAggregators: [String: PollAggregator] = [:]
    private var targetTimestamp: Date?
    private var oldestEventDateSubject: CurrentValueSubject<Date, Never> = .init(Date.distantFuture)
    private var currentBatchSubject: PassthroughSubject<TimelinePollDetails, Error>?
    
    var updates: AnyPublisher<TimelinePollDetails, Never> {
        updatesSubject.eraseToAnyPublisher()
    }
    
    var pollErrors: AnyPublisher<Error, Never> {
        pollErrorsSubject.eraseToAnyPublisher()
    }
    
    init(room: MXRoom, chunkSizeInDays: UInt) {
        self.room = room
        self.chunkSizeInDays = chunkSizeInDays
        timeline = MXRoomEventTimeline(room: room, andInitialEventId: nil)
        setupTimeline()
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
}

private extension PollHistoryService {
    enum Constants {
        static let pageSize: UInt = 250
    }
    
    func setupTimeline() {
        timeline.resetPagination()
        
        timelineListener = timeline.listenToEvents { [weak self] event, _, _ in
            if event.eventType == .pollStart {
                self?.aggregatePoll(pollStartEvent: event)
            }
           
            self?.updateTimestamp(event: event)
        }
    }
    
    func updateTimestamp(event: MXEvent) {
        oldestEventDate = min(event.originServerDate, oldestEventDate)
    }
    
    func startPagination() -> AnyPublisher<TimelinePollDetails, Error> {
        let startingTimestamp = targetTimestamp ?? .init()
        targetTimestamp = startingTimestamp.subtractingDays(chunkSizeInDays)
        
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
        guard let targetTimestamp = targetTimestamp else {
            return true
        }
        return oldestEventDate <= targetTimestamp
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
    func subtractingDays(_ days: UInt) -> Date {
        addingTimeInterval(-TimeInterval(days) * PollHistoryConstants.oneDayInSeconds)
    }
}

private extension MXEvent {
    var originServerDate: Date {
        .init(timeIntervalSince1970: Double(originServerTs) / 1000)
    }
}

// MARK: - PollAggregatorDelegate

extension PollHistoryService: PollAggregatorDelegate {
    func pollAggregatorDidStartLoading(_ aggregator: PollAggregator) {}
    
    func pollAggregatorDidEndLoading(_ aggregator: PollAggregator) {
        currentBatchSubject?.send(.init(poll: aggregator.poll, represent: .started))
    }
    
    func pollAggregator(_ aggregator: PollAggregator, didFailWithError: Error) {
        pollErrorsSubject.send(didFailWithError)
    }
    
    func pollAggregatorDidUpdateData(_ aggregator: PollAggregator) {
        updatesSubject.send(.init(poll: aggregator.poll, represent: .started))
    }
}
