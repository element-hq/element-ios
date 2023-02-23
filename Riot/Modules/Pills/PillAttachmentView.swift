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
@available (iOS 15.0, *)
@objcMembers
class PillAttachmentView: UIView {
    // MARK: - Internal Structs
    /// Sizes provided alongside frame to build `PillAttachmentView` layout.
    struct Sizes {
        var verticalMargin: CGFloat
        var horizontalMargin: CGFloat
        var avatarSideLength: CGFloat

        var pillBackgroundHeight: CGFloat {
            return avatarSideLength + 2 * verticalMargin
        }
        var pillHeight: CGFloat {
            return pillBackgroundHeight + 2 * verticalMargin
        }
        var displaynameLabelLeading: CGFloat {
            return avatarSideLength + 2 * horizontalMargin
        }
        var totalWidthWithoutLabel: CGFloat {
            return displaynameLabelLeading + 2 * horizontalMargin
        }
    }

    // MARK: - Init
    /// Create a Mention Pill view for given data.
    ///
    /// - Parameters:
    ///   - frame: the frame of the view
    ///   - sizes: additional size parameters
    ///   - theme: current theme
    ///   - mediaManager: the media manager if available
    ///   - pillData: the pill data
    convenience init(frame: CGRect,
                     sizes: Sizes,
                     theme: Theme,
                     mediaManager: MXMediaManager?,
                     andPillData pillData: PillTextAttachmentData) {
        self.init(frame: frame)
        let label = UILabel(frame: .zero)
        label.text = pillData.displayText
        label.font = pillData.font
        label.textColor = pillData.isHighlighted ? theme.baseTextPrimaryColor : theme.textPrimaryColor
        let labelSize = label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                  height: sizes.pillBackgroundHeight))
        label.frame = CGRect(x: sizes.displaynameLabelLeading,
                             y: 0,
                             width: labelSize.width,
                             height: sizes.pillBackgroundHeight)

        let pillBackgroundView = UIView(frame: CGRect(x: 0,
                                        y: sizes.verticalMargin,
                                        width: labelSize.width + sizes.totalWidthWithoutLabel,
                                        height: sizes.pillBackgroundHeight))

        let avatarView = UserAvatarView(frame: CGRect(x: sizes.horizontalMargin,
                                                      y: sizes.verticalMargin,
                                                      width: sizes.avatarSideLength,
                                                      height: sizes.avatarSideLength))

        avatarView.fill(with: AvatarViewData(matrixItemId: pillData.matrixItemId,
                                             displayName: pillData.displayName,
                                             avatarUrl: pillData.avatarUrl,
                                             mediaManager: mediaManager,
                                             fallbackImage: .matrixItem(pillData.matrixItemId, pillData.displayName)))
        avatarView.isUserInteractionEnabled = false

        pillBackgroundView.addSubview(avatarView)
        pillBackgroundView.addSubview(label)

        pillBackgroundView.backgroundColor = pillData.isHighlighted ? theme.colors.alert : theme.colors.quinaryContent
        pillBackgroundView.layer.cornerRadius = sizes.pillBackgroundHeight / 2.0

        self.addSubview(pillBackgroundView)
        self.alpha = pillData.alpha
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
