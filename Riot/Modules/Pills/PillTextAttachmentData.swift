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
import UIKit

/// Data associated with a Pill text attachment.
@available (iOS 15.0, *)
struct PillTextAttachmentData: Codable {
    // MARK: - Properties
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
    /// Font for the display name
    var font: UIFont

    /// Helper for preferred text to display.
    var displayText: String {
        guard let displayName = displayName,
              displayName.count > 0 else {
            return matrixItemId
        }

        return displayName
    }

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///   - matrixItemId: Matrix item identifier (user id or room id)
    ///   - displayName: Matrix item display name (user or room display name)
    ///   - avatarUrl: Matrix item avatar URL (user or room avatar url)
    ///   - isHighlighted: Wether the pill should be highlighted
    ///   - alpha: Alpha for pill display
    ///   - font: Font for the display name
    init(matrixItemId: String,
         displayName: String?,
         avatarUrl: String?,
         isHighlighted: Bool,
         alpha: CGFloat,
         font: UIFont) {
        self.matrixItemId = matrixItemId
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.isHighlighted = isHighlighted
        self.alpha = alpha
        self.font = font
    }

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case matrixItemId
        case displayName
        case avatarUrl
        case isHighlighted
        case alpha
        case font
    }

    enum PillTextAttachmentDataError: Error {
        case noFontData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        matrixItemId = try container.decode(String.self, forKey: .matrixItemId)
        displayName = try? container.decode(String.self, forKey: .displayName)
        avatarUrl = try? container.decode(String.self, forKey: .avatarUrl)
        isHighlighted = try container.decode(Bool.self, forKey: .isHighlighted)
        alpha = try container.decode(CGFloat.self, forKey: .alpha)
        let fontData = try container.decode(Data.self, forKey: .font)
        if let font = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIFont.self, from: fontData) {
            self.font = font
        } else {
            throw PillTextAttachmentDataError.noFontData
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(matrixItemId, forKey: .matrixItemId)
        try? container.encode(displayName, forKey: .displayName)
        try? container.encode(avatarUrl, forKey: .avatarUrl)
        try container.encode(isHighlighted, forKey: .isHighlighted)
        try container.encode(alpha, forKey: .alpha)
        let fontData = try NSKeyedArchiver.archivedData(withRootObject: font, requiringSecureCoding: false)
        try container.encode(fontData, forKey: .font)
    }
}
