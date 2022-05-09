// 
// Copyright 2022 New Vector Ltd
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

/// Data associated with a Pill text attachment.
@available (iOS 15.0, *)
struct PillTextAttachmentData: Codable {
    /// Matrix item identifier (user id or room id)
    var matrixItemId: String
    /// Matrix item display name (user or room display name)
    var displayName: String?
    /// Matrix item avatar URL (user or room avatar url)
    var avatarUrl: String?
    /// Wether the pill should be highlighted
    var isHighlighted: Bool
    /// Alpha for pill display
    var alpha: CGFloat

    /// Helper for preferred text to display.
    var displayText: String {
        guard let displayName = displayName,
              displayName.count > 0 else {
            return matrixItemId
        }

        return displayName
    }
}
