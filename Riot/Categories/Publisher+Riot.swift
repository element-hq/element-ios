// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine

extension Publisher {
    
    ///
    /// Buffer upstream items and guarantee a time interval spacing out the published items.
    /// - Parameters:
    ///   - spacingDelay: A delay in seconds to guarantee between emissions
    ///   - scheduler: The `DispatchQueue` on which to schedule emissions.
    /// - Returns: The new wrapped publisher
    func bufferAndSpace(spacingDelay: Int, scheduler: DispatchQueue = DispatchQueue.main) -> Publishers.FlatMap<
        Publishers.SetFailureType<Publishers.Delay<Just<Publishers.Buffer<Self>.Output>, DispatchQueue>, Publishers.Buffer<Self>.Failure>,
        Publishers.Buffer<Self>
    > {
         return buffer(size: .max, prefetch: .byRequest, whenFull: .dropNewest)
        .flatMap(maxPublishers: .max(1)) {
            Just($0).delay(for: .seconds(spacingDelay), scheduler: scheduler)
        }
    }
    
    func eraseOutput() -> AnyPublisher<Void, Failure> {
        self
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}
