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

/// An `Activity` represents the state of a temporary visual indicator, such as activity indicator, success notification or an error message. It does not directly manage the UI, instead it delegates to a `presenter`
/// whenever the UI should be shown or hidden.
///
/// More than one `Activity` may be requested by the system at the same time (e.g. global syncing vs local refresh),
/// and the `ActivityCenter` will ensure that only one activity is shown at a given time, putting the other in a pending queue.
///
/// A client that requests an activity can specify a default timeout after which the activity is dismissed, or it has to be manually
/// responsible for dismissing it via `cancel` method, or by deallocating itself.
public class Activity {
    enum State {
        case pending
        case executing
        case completed
    }
    
    private let request: ActivityRequest
    private let completion: () -> Void

    private(set) var state: State
    
    public init(request: ActivityRequest, completion: @escaping () -> Void) {
        self.request = request
        self.completion = completion
        
        state = .pending
    }
    
    deinit {
        cancel()
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
    
    /// Cancel the activity, triggering any dismissal action / animation
    ///
    /// Note: clients can call this method directly, if they have access to the `Activity`.
    /// Once cancelled, `ActivityCenter` will automatically start the next `Activity` in the queue.
    func cancel() {
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

public extension Activity {
    func store<C>(in collection: inout C) where C: RangeReplaceableCollection, C.Element == Activity {
        collection.append(self)
    }
}
