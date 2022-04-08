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
import UIKit

/// A `UserIndicator` represents the state of a temporary visual indicator, such as loading spinner, success notification or an error message. It does not directly manage the UI, instead it delegates to a `presenter`
/// whenever the UI should be shown or hidden.
///
/// More than one `UserIndicator` may be requested by the system at the same time (e.g. global syncing vs local refresh),
/// and the `UserIndicatorQueue` will ensure that only one indicator is shown at a given time, putting the other in a pending queue.
///
/// A client that requests an indicator can specify a default timeout after which the indicator is dismissed, or it has to be manually
/// responsible for dismissing it via `cancel` method, or by deallocating itself.
public class UserIndicator {
    public enum State {
        case pending
        case executing
        case completed
    }
    
    private let request: UserIndicatorRequest
    private let completion: () -> Void

    public private(set) var state: State
    
    public init(request: UserIndicatorRequest, completion: @escaping () -> Void) {
        self.request = request
        self.completion = completion
        
        state = .pending
    }
    
    deinit {
        complete()
    }
    
    internal func start() {
        guard state == .pending else {
            return
        }
        
        state = .executing
        request.presenter.present()
        
        switch request.dismissal {
        case .manual:
            break
        case .timeout(let interval):
            Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
                self?.complete()
            }
        }
    }
    
    /// Cancel the indicator, triggering any dismissal action / animation
    ///
    /// Note: clients can call this method directly, if they have access to the `UserIndicator`. Alternatively
    /// deallocating the `UserIndicator` will call `cancel` automatically.
    /// Once cancelled, `UserIndicatorQueue` will automatically start the next `UserIndicator` in the queue.
    public func cancel() {
        complete()
    }
    
    private func complete() {
        guard state != .completed else {
            return
        }
        if state == .executing {
            request.presenter.dismiss()
        }
        
        state = .completed
        completion()
    }
}

public extension UserIndicator {
    func store<C>(in collection: inout C) where C: RangeReplaceableCollection, C.Element == UserIndicator {
        collection.append(self)
    }
}

public extension Collection where Element == UserIndicator {
    func cancelAll() {
        forEach {
            $0.cancel()
        }
    }
}
