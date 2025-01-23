// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit
import MatrixSDK

/// Text attachment for pills display.
@available(iOS 15.0, *)
@objcMembers
class PillTextAttachment: NSTextAttachment {
    // MARK: - Properties
    /// Return `PillTextAttachmentData` contained in the text attachment.
    var data: PillTextAttachmentData? {
        get {
            guard let contents = contents else { return nil }
            return try? Self.serializationService.deserialize(contents)
        }
        set {
            guard let newValue = newValue else {
                contents = nil
                return
            }
            contents = try? Self.serializationService.serialize(newValue)
            updateBounds()
        }
    }
    private static let serializationService: SerializationServiceType = SerializationService()

    // MARK: - Init
    override init(data contentData: Data?, ofType uti: String?) {
        super.init(data: contentData, ofType: uti)

        updateBounds()
    }
    
    convenience init?(attachmentData: PillTextAttachmentData) {
        guard let encodedData = try? Self.serializationService.serialize(attachmentData) else { return nil }
        self.init(data: encodedData, ofType: PillsFormatter.pillUTType)
    }

    /// Create a Mention Pill text attachment for given room member.
    ///
    /// - Parameters:
    ///   - roomMember: the room member
    ///   - isHighlighted: whether this pill should be highlighted
    ///   - font: the text font
    convenience init?(withRoomMember roomMember: MXRoomMember,
                      isHighlighted: Bool,
                      font: UIFont) {
        let data = PillTextAttachmentData(pillType: .user(userId: roomMember.userId),
                                          items: [
                                            .avatar(url: roomMember.avatarUrl,
                                                    string: roomMember.displayname,
                                                    matrixId: roomMember.userId),
                                            .text(roomMember.displayname ?? roomMember.userId)
                                          ],
                                          isHighlighted: isHighlighted,
                                          alpha: 1.0,
                                          font: font)

        guard let encodedData = try? Self.serializationService.serialize(data) else { return nil }
        self.init(data: encodedData, ofType: PillsFormatter.pillUTType)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        updateBounds()
    }
    
    /// Computes size required to display a pill for given display text.
    ///
    /// - Parameters:
    ///   - font: the text font
    /// - Returns: required size for pill
    func size(forFont font: UIFont) -> CGSize {
        guard let data else {
            MXLog.debug("[PillTextAttachment]: data are missing")
            return .zero
        }
        
        let sizes = PillAttachmentViewProvider.pillAttachmentViewSizes

        var width: CGFloat = 0

        var textContent = ""
        for item in data.items {
            switch item {
            case .text(let text):
                textContent += text
            case .avatar, .asset, .spaceAvatar:
                width += sizes.avatarSideLength
            }
        }
                
        // add texts
        if !textContent.isEmpty {
            let label = UILabel(frame: .zero)
            label.font = font
            label.text = textContent
            width += label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude,
                                               height: sizes.pillBackgroundHeight)).width
        }
        
        // add spacing
        width += CGFloat(max(0, data.items.count - 1)) * sizes.itemSpacing
        // add margins
        switch data.items.first {
        case .asset, .avatar:
            width += sizes.avatarLeading + sizes.horizontalMargin
        default:
            width += 2 * sizes.horizontalMargin
        }

        width = min(width, data.maxWidth)

        return CGSize(width: width,
                      height: sizes.pillHeight)
    }
}

// MARK: - Private
@available(iOS 15.0, *)
private extension PillTextAttachment {
        
    func updateBounds() {
        guard let data = data else { return }
        let pillSize = size(forFont: data.font)
        // Offset to align pill centerY with text centerY.
        let offset = data.font.descender + (data.font.lineHeight - pillSize.height) / 2.0
        self.bounds = CGRect(origin: CGPoint(x: 0.0, y: offset), size: pillSize)
    }
}
