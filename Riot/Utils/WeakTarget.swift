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

/**
 Used to avoid retain cycles by creating a proxy that holds a weak reference to the original object.
 One example of that would be using CADisplayLink, which strongly retains its target, when manually invalidating it is unfeasable.
 */
class WeakTarget: NSObject {
    private(set) weak var target: AnyObject?
    let selector: Selector

    static let triggerSelector = #selector(WeakTarget.handleTick(parameter:))

    init(_ target: AnyObject, selector: Selector) {
        self.target = target
        self.selector = selector
    }

    @objc private func handleTick(parameter: Any) {
        _ = self.target?.perform(self.selector, with: parameter)
    }
}
