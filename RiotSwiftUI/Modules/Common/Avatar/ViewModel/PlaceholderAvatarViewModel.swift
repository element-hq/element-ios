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

/// Simple view model that computes the placeholder avatar properties.
struct PlaceholderAvatarViewModel {
    /// The displayname used to create the `firstCharacterCapitalized`.
    let displayName: String?
    /// The matrix id used as input to create the `stableColorIndex` from.
    let matrixItemId: String
    /// The number of total colors available for the `stableColorIndex`.
    let colorCount: Int
    
    /// Get the first character of the display name capitalized or else a space character.
    var firstCharacterCapitalized: Character {
        displayName?.capitalized.first ?? " "
    }
    
    /// Provides the same color each time for a specified matrixId
    ///
    /// Same algorithm as in AvatarGenerator.
    /// - Parameters:
    ///   - matrixItemId: the matrix id used as input to create the stable index.
    /// - Returns: The stable index.
    var stableColorIndex: Int {
        // Sum all characters
        let sum = matrixItemId.utf8
            .map { UInt($0) }
            .reduce(0, +)
        // modulo the color count
        return Int(sum) % colorCount
    }
}
