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
    /// Returns a Publisher publishing the polls in the next batch.
    /// Implementations should return the same publisher if `nextBatch()` is called again before the previous publisher completes.
    func nextBatch() -> AnyPublisher<TimelinePollDetails, Error>
    
    /// Publishes updates for the polls previously pusblished by the `nextBatch()` or `livePolls` publishers.
    var updates: AnyPublisher<TimelinePollDetails, Never> { get }
    
    /// Publishes live polls not related with the current batch.
    var livePolls: AnyPublisher<TimelinePollDetails, Never> { get }
    
    /// Returns true every time the service can fetch another batch.
    /// There is no guarantee the `nextBatch()` returned publisher will publish something anyway.
    var hasNextBatch: Bool { get }
    
    /// Publishes the date up to the service is synced (in the past).
    /// This date doesn't need to be related with any poll event.
    var fetchedUpTo: AnyPublisher<Date, Never> { get }
}
