// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
