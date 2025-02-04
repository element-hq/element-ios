// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Class to build an event menu.
@objcMembers
class EventMenuBuilder: NSObject {
    
    private var items: [EventMenuItemType: UIAlertAction] = [:]
    
    /// Returns true if no items or only one item with the type `EventMenuItemType.cancel`.
    var isEmpty: Bool {
        return items.isEmpty || (items.count == 1 && items.first?.key == .cancel)
    }
    
    /// Add a menu item.
    /// - Parameters:
    ///   - type: item type
    ///   - action: alert action
    func addItem(withType type: EventMenuItemType,
                 action: UIAlertAction) {
        items[type] = action
    }
    
    /// Builds the action menu items.
    /// - Returns: alert actions. Sorted by item types.
    func build() -> [UIAlertAction] {
        items.sorted(by: { $0.key < $1.key }).map { $1 }
    }
    
    /// Reset the builder. Builder will be empty after this method call.
    func reset() {
        items.removeAll()
    }
    
}
