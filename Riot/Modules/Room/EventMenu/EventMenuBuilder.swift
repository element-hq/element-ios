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
