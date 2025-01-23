//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
