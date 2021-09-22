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

/// Index that determines the state of the push setting.
///
/// Silent case is un-used on iOS but keeping in for consistency of
/// definition across the platforms.
enum NotificationIndex {
    case off
    case silent
    case noisy
}

extension NotificationIndex: CaseIterable { }

extension NotificationIndex {
    /// Used to map the on/off checkmarks to an index used in the static push rule definitions.
    /// - Parameter enabled: Enabled/Disabled state.
    /// - Returns: The associated NotificationIndex
    static func index(when enabled: Bool) -> NotificationIndex {
        return enabled ? .noisy : .off
    }
    
    /// Used to map from the checked state back to the index.
    var enabled: Bool {
        return self != .off
    }
}
