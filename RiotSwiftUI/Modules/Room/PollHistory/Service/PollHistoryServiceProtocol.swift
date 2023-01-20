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

protocol PollHistoryServiceProtocol {
    /// Publishes poll data as soon they are found in the timeline.
    /// Updates are also published here, so clients needs to address duplicates.
    var pollHistory: AnyPublisher<TimelinePollDetails, Never> { get }
    
    /// Publishes whatever errors produced during the sync.
    var error: AnyPublisher<PollHistoryError, Never> { get }
    
    /// Ask to fetch the next batch of polls.
    /// Concrete implementations can decide what a batch is.
    func next()
    
    /// Inform whenever the fetch of a new batch of polls starts or ends.
    var isFetching: AnyPublisher<Bool, Never> { get }
}

enum PollHistoryError: Error {
    case paginationFailed(Error)
    case timelineUnavailable
    case pollAggregationFailed(Error)
}
