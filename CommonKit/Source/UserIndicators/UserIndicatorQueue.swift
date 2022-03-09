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

import Foundation

/// A FIFO queue which will ensure only one user indicator is shown at a given time.
///
/// `UserIndicatorQueue` offers a `shared` queue that can be used by any clients app-wide, but clients are also allowed
/// to create local `UserIndicatorQueue` if the context requres multiple simultaneous indicators.
public class UserIndicatorQueue {
    private class Weak<T: AnyObject> {
        weak var element: T?
        init(_ element: T) {
            self.element = element
        }
    }
    
    private var queue: [Weak<UserIndicator>]
    
    public init() {
        queue = []
    }
    
    /// Add a new indicator to the queue by providing a request.
    ///
    /// The queue will start the indicator right away, if there are no currently running indicators,
    /// otherwise the indicator will be put on hold.
    public func add(_ request: UserIndicatorRequest) -> UserIndicator {
        let indicator = UserIndicator(request: request) { [weak self] in
            self?.startNextIfIdle()
        }
        
        queue.append(Weak(indicator))
        startNextIfIdle()
        return indicator
    }
    
    private func startNextIfIdle() {
        cleanup()
        if let indicator = queue.first?.element, indicator.state == .pending {
            indicator.start()
        }
    }
    
    private func cleanup() {
        queue.removeAll {
            $0.element == nil || $0.element?.state == .completed
        }
    }
}
