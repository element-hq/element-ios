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

import UIKit

/// Base view class for mention Pills.
class PillAttachmentView: UIView {
    /// Computes size required to display a pill for given room member.
    ///
    /// - Parameter roomMember: room member to display in the pill
    /// - Returns: required size for pill
    static func size(forRoomMember roomMember: MXRoomMember) -> CGSize {
        let label = UILabel(frame: .zero)
        label.text = roomMember.displayname
        label.font = Constants.pillLabelFont
        let labelSize = label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                  height: Constants.pillBackgroundHeight))

        return CGSize(width: labelSize.width + Constants.totalWidthWithoutLabel,
                      height: Constants.pillHeight)
    }

    // MARK: - Private Enums
    private enum Constants {
        static let pillLabelFont: UIFont = ThemeService.shared().theme.fonts.body
        static let commonVerticalMargin: CGFloat = 2.0
        static let commonHorizontalMargin: CGFloat = 4.0
        static let avatarSideLength: CGFloat = 16.0
        static let pillBackgroundHeight: CGFloat = avatarSideLength + 2 * commonVerticalMargin
        static let displaynameLabelLeading: CGFloat = avatarSideLength + 2 * commonHorizontalMargin
        static let pillHeight: CGFloat = pillBackgroundHeight + 2 * commonVerticalMargin
        static let displaynameLabelTrailing: CGFloat = 2 * commonHorizontalMargin
        static let totalWidthWithoutLabel: CGFloat = displaynameLabelLeading + displaynameLabelTrailing
    }

    // MARK: - Init
    convenience init(withRoomMember roomMember: MXRoomMember, isCurrentUser: Bool) {
        self.init(frame: CGRect(origin: CGPoint(x: 0.0, y: 0.0),
                                size: Self.size(forRoomMember: roomMember)))

        let label = UILabel(frame: .zero)
        label.text = roomMember.displayname
        label.font = Constants.pillLabelFont
        label.textColor = isCurrentUser ? ThemeService.shared().theme.baseTextPrimaryColor : ThemeService.shared().theme.textPrimaryColor
        let labelSize = label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                  height: CGFloat.greatestFiniteMagnitude))
        label.frame = CGRect(x: Constants.displaynameLabelLeading,
                             y: 0,
                             width: labelSize.width,
                             height: Constants.pillBackgroundHeight)

        let pillBackgroundView = UIView(frame: CGRect(x: 0,
                                        y: Constants.commonVerticalMargin,
                                        width: labelSize.width + Constants.totalWidthWithoutLabel,
                                        height: Constants.pillBackgroundHeight))

        let imageView = MXKImageView(frame: CGRect(x: Constants.commonHorizontalMargin,
                                                   y: Constants.commonVerticalMargin,
                                                   width: Constants.avatarSideLength,
                                                   height: Constants.avatarSideLength))
        imageView.setImageURI(roomMember.avatarUrl,
                              withType: nil,
                              andImageOrientation: .up,
                              toFitViewSize: imageView.frame.size,
                              with: MXThumbnailingMethodCrop,
                              previewImage: Asset.Images.userIcon.image,
                              // Pills rely only on cached images since `MXKImageView` image loading
                              // is not handled properly for a `NSTextAttachment` view.
                              mediaManager: nil)
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = Constants.avatarSideLength / 2.0
        imageView.backgroundColor = .clear
        pillBackgroundView.addSubview(imageView)
        pillBackgroundView.addSubview(label)

        pillBackgroundView.backgroundColor = isCurrentUser ? ThemeService.shared().theme.colors.alert : ThemeService.shared().theme.colors.quinaryContent
        pillBackgroundView.layer.cornerRadius = Constants.pillBackgroundHeight / 2.0

        self.addSubview(pillBackgroundView)
    }

    // MARK: - Override
    override var isHidden: Bool {
        get {
            return false
        }
        // swiftlint:disable:next unused_setter_value
        set {
            // Disable isHidden for pills, fixes a bug where the system sometimes
            // hides attachment views for undisclosed reasons. Pills never needs to be hidden.
        }
    }
}
