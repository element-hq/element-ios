// 
// Copyright 2021 New Vector Ltd
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
}
