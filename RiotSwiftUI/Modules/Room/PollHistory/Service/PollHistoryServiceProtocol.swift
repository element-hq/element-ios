//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
