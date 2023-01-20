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

import MatrixSDK
import Foundation
import Combine

final class PollHistoryService: PollHistoryServiceProtocol {
    private let room: MXRoom
    private let pollsSubject: PassthroughSubject<TimelinePollDetails, Never> = .init()
    private let errorSubject: PassthroughSubject<Error, Never> = .init()
    private let isFetchingSubject: PassthroughSubject<Bool, Never> = .init()
    
    private var listner: Any?
    private var timeline: MXEventTimeline?
    private var pollAggregators: [String: PollAggregator] = [:]
    private var targetTimestamp: Date
    
    var pollHistory: AnyPublisher<TimelinePollDetails, Never> {
        pollsSubject.eraseToAnyPublisher()
    }
    
    var error: AnyPublisher<Error, Never> {
        errorSubject.eraseToAnyPublisher()
    }
    
    var isFetching: AnyPublisher<Bool, Never> {
        isFetchingSubject.eraseToAnyPublisher()
    }
    
    init(room: MXRoom) {
        self.room = room
        self.targetTimestamp = Date().addingTimeInterval(-TimeInterval(Constants.daysToSync) * Constants.oneDayInSeconds)
    }
    
    func next() {
        guard timeline == nil else {
            paginate()
            return
        }
        
        room.liveTimeline { [weak self] timeline in
            guard
                let self = self,
                let timeline = timeline
            else {
                #warning("Handle error")
                return
            }
            
            self.setup(timeline: timeline)
            self.paginate()
        }
    }
}

private extension PollHistoryService {
    enum Constants {
        static let pageSize: UInt = 250
        static let daysToSync: UInt = 30
        static let oneDayInSeconds: TimeInterval = 8.6 * 10e3
    }
    
    func setup(timeline: MXEventTimeline) {
        self.timeline = timeline
        listner = timeline.listenToEvents([MXEventType.pollStart]) { [weak self] event, direction, roomState in
            self?.aggregatePoll(pollStartEvent: event)
        }
    }
    
    func paginate() {
        guard let timeline = timeline else  {
            return
        }
        
        timeline.resetPagination()
        
        isFetchingSubject.send(true)
        timeline.paginate(Constants.pageSize,
                          direction: .backwards,
                          onlyFromStore: false) { [weak self] response in
            self?.isFetchingSubject.send(false)
            
            switch response {
            case .success:
                #warning("Go on with pagination...")
                break
            case .failure(let error):
                #warning("Handle error")
                break
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
}

// MARK: - PollAggregatorDelegate

extension PollHistoryService: PollAggregatorDelegate {
    func pollAggregatorDidStartLoading(_ aggregator: PollAggregator) {
    }
    
    func pollAggregatorDidEndLoading(_ aggregator: PollAggregator) {
        pollsSubject.send(.init(poll: aggregator.poll, represent: .started))
    }
    
    func pollAggregator(_ aggregator: PollAggregator, didFailWithError: Error) {
    }
    
    func pollAggregatorDidUpdateData(_ aggregator: PollAggregator) {
        
    }
}
