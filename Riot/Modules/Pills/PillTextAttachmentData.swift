// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit

@available(iOS 15.0, *)
struct PillAssetColor: Codable {
    var red: CGFloat = 0.0, green: CGFloat = 0.0, blue: CGFloat = 0.0, alpha: CGFloat = 0.0
    
    var uiColor: UIColor {
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    init(uiColor: UIColor) {
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    }
}

@available(iOS 15.0, *)
struct PillAssetParameter: Codable {
    var tintColor: PillAssetColor?
    var backgroundColor: PillAssetColor?
    var rawRenderingMode: Int = UIImage.RenderingMode.automatic.rawValue
    var padding: CGFloat = 2.0
}

@available(iOS 15.0, *)
enum PillTextAttachmentItem: Codable {
    case text(String)
    case avatar(url: String?, string: String?, matrixId: String)
    case spaceAvatar(url: String?, string: String?, matrixId: String)
    case asset(named: String, parameters: PillAssetParameter)
}

@available(iOS 15.0, *)
extension PillTextAttachmentItem {
    var string: String? {
        switch self {
        case .text(let text):
            return text
        default:
            return nil
        }
    }
}

/// Data associated with a Pill text attachment.
@available(iOS 15.0, *)
struct PillTextAttachmentData: Codable {
    // MARK: - Properties
    /// Pill type
    var pillType: PillType
    /// Items to render
    var items: [PillTextAttachmentItem]
    /// Wether the pill should be highlighted
    var isHighlighted: Bool
    /// Alpha for pill display
    var alpha: CGFloat
    /// Font for the display name
    var font: UIFont
    /// Max width
    var maxWidth: CGFloat

    /// Helper for preferred text to display.
    var displayText: String {
        return items.map { $0.string }
            .compactMap { $0 }
            .joined(separator: " ")
    }
        
    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///   - pillType: Type for the pill
    ///   - items: Items to display
    ///   - isHighlighted: Wether the pill should be highlighted
    ///   - alpha: Alpha for pill display
    ///   - font: Font for the display name
    init(pillType: PillType,
         items: [PillTextAttachmentItem],
         isHighlighted: Bool,
         alpha: CGFloat,
         font: UIFont,
         maxWidth: CGFloat = .greatestFiniteMagnitude) {
        self.pillType = pillType
        self.items = items
        self.isHighlighted = isHighlighted
        self.alpha = alpha
        self.font = font
        self.maxWidth = maxWidth
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case pillType
        case items
        case isHighlighted
        case alpha
        case font
    }

    enum PillTextAttachmentDataError: Error {
        case noFontData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pillType = try container.decode(PillType.self, forKey: .pillType)
        items = try container.decode([PillTextAttachmentItem].self, forKey: .items)
        isHighlighted = try container.decode(Bool.self, forKey: .isHighlighted)
        alpha = try container.decode(CGFloat.self, forKey: .alpha)
        let fontData = try container.decode(Data.self, forKey: .font)
        if let font = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIFont.self, from: fontData) {
            self.font = font
        } else {
            throw PillTextAttachmentDataError.noFontData
        }
        maxWidth = .greatestFiniteMagnitude
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pillType, forKey: .pillType)
        try container.encode(items, forKey: .items)
        try container.encode(isHighlighted, forKey: .isHighlighted)
        try container.encode(alpha, forKey: .alpha)
        let fontData = try NSKeyedArchiver.archivedData(withRootObject: font, requiringSecureCoding: false)
        try container.encode(fontData, forKey: .font)
    }
    
    // MARK: - Pill representations
    var pillIdentifier: String {
        switch pillType {
        case .user(let userId):
            return userId
        case .room(let roomId):
            return roomId
        case .message(let roomId, let messageId):
            return "\(roomId)/\(messageId)"
        }
    }
    
    var markdown: String {
        var permalink: String
        switch pillType {
        case .user(let userId):
            permalink = MXTools.permalinkToUser(withUserId: userId)
        case .room(let roomId):
            permalink = MXTools.permalink(toRoom: roomId)
        case .message(let roomId, let messageId):
            permalink = MXTools.permalink(toEvent: messageId, inRoom: roomId)
        }
        return "[\(displayText)](\(permalink))"
    }
}
