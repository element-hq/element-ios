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
import SwiftUI

extension ThemeSwiftUI {
    /// Get the stable display user color based on userId.
    /// - Parameter userId: The user id used to hash.
    /// - Returns: The SwiftUI color for the associated userId.
    func userColor(for userId: String) -> Color {
        let senderNameColorIndex = Int(userId.vc_hashCode % Int32(colors.namesAndAvatars.count))
        return colors.namesAndAvatars[senderNameColorIndex]
    }
}
