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

/// A shared activity center with a single FIFO queue which will ensure only one activity is shown at a given time.
///
/// `ActivityCenter` offers a `shared` center that can be used by any clients, but clients are also allowed
/// to create local `ActivityCenter` if the context requres multiple simultaneous activities.
public class ActivityCenter {
    private class Weak<T: AnyObject> {
        weak var element: T?
        init(_ element: T) {
            self.element = element
        }
    }
    
    public static let shared = ActivityCenter()
    private var queue = [Weak<Activity>]()
    
    /// Add a new activity to the queue by providing a request.
    ///
    /// The queue will start the activity right away, if there are no currently running activities,
    /// otherwise the activity will be put on hold.
    public func add(_ request: ActivityRequest) -> Activity {
        let activity = Activity(request: request) { [weak self] in
            self?.startNextIfIdle()
        }
        
        queue.append(Weak(activity))
        startNextIfIdle()
        return activity
    }
    
    private func startNextIfIdle() {
        cleanup()
        if let activity = queue.first?.element, activity.state == .pending {
            activity.start()
        }
    }
    
    private func cleanup() {
        queue.removeAll {
            $0.element == nil || $0.element?.state == .completed
        }
    }
}
