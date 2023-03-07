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
        var avatarLeading: CGFloat
        var avatarSideLength: CGFloat
        var itemSpacing: CGFloat

        var pillBackgroundHeight: CGFloat {
            return avatarSideLength + 2 * verticalMargin
        }
        var pillHeight: CGFloat {
            return pillBackgroundHeight + 2 * verticalMargin
        }
        var totalWidthWithoutLabel: CGFloat {
            return avatarSideLength + 2 * horizontalMargin
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
        
        let stack = UIStackView(frame: frame)
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = sizes.itemSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false

        var computedWidth: CGFloat = 0
        for item in pillData.items {
            switch item {
            case .text(let string):
                let label = UILabel(frame: .zero)
                label.text = string
                label.font = pillData.font
                label.textColor = pillData.isHighlighted ? theme.baseTextPrimaryColor : theme.textPrimaryColor
                label.translatesAutoresizingMaskIntoConstraints = false
                label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                stack.addArrangedSubview(label)
                
                computedWidth += label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: sizes.pillBackgroundHeight)).width

            case .avatar(let url, let alt, let matrixId):
                let avatarView = UserAvatarView(frame: CGRect(origin: .zero, size: CGSize(width: sizes.avatarSideLength, height: sizes.avatarSideLength)))

                avatarView.fill(with: AvatarViewData(matrixItemId: matrixId,
                                                     displayName: alt,
                                                     avatarUrl: url,
                                                     mediaManager: mediaManager,
                                                     fallbackImage: .matrixItem(matrixId, alt)))
                avatarView.isUserInteractionEnabled = false
                avatarView.translatesAutoresizingMaskIntoConstraints = false
                stack.addArrangedSubview(avatarView)
                NSLayoutConstraint.activate([
                    avatarView.widthAnchor.constraint(equalToConstant: sizes.avatarSideLength),
                    avatarView.heightAnchor.constraint(equalToConstant: sizes.avatarSideLength)
                ])
                
                computedWidth += sizes.avatarSideLength
                
            case .spaceAvatar(let url, let alt, let matrixId):
                let avatarView = SpaceAvatarView(frame: CGRect(origin: .zero, size: CGSize(width: sizes.avatarSideLength, height: sizes.avatarSideLength)))

                avatarView.fill(with: AvatarViewData(matrixItemId: matrixId,
                                                     displayName: alt,
                                                     avatarUrl: url,
                                                     mediaManager: mediaManager,
                                                     fallbackImage: .matrixItem(matrixId, alt)))
                avatarView.isUserInteractionEnabled = false
                avatarView.translatesAutoresizingMaskIntoConstraints = false
                stack.addArrangedSubview(avatarView)
                NSLayoutConstraint.activate([
                    avatarView.widthAnchor.constraint(equalToConstant: sizes.avatarSideLength),
                    avatarView.heightAnchor.constraint(equalToConstant: sizes.avatarSideLength)
                ])
                
                computedWidth += sizes.avatarSideLength
                
            case .asset(let name):
                let assetView = UIView(frame: CGRect(x: 0, y: 0, width: sizes.avatarSideLength, height: sizes.avatarSideLength))
                assetView.backgroundColor = theme.colors.links
                assetView.layer.cornerRadius = sizes.avatarSideLength / 2
                assetView.isUserInteractionEnabled = false
                assetView.translatesAutoresizingMaskIntoConstraints = false

                let imageView = UIImageView(frame: .zero)
                imageView.image = ImageAsset(name: name).image.withRenderingMode(.alwaysTemplate)
                imageView.tintColor = theme.baseIconPrimaryColor
                imageView.contentMode = .scaleAspectFit
                imageView.translatesAutoresizingMaskIntoConstraints = false
                
                assetView.addSubview(imageView)
                NSLayoutConstraint.activate([
                    imageView.leadingAnchor.constraint(equalTo: assetView.leadingAnchor, constant: 2),
                    imageView.trailingAnchor.constraint(equalTo: assetView.trailingAnchor, constant: -2),
                    imageView.topAnchor.constraint(equalTo: assetView.topAnchor, constant: 2),
                    imageView.bottomAnchor.constraint(equalTo: assetView.bottomAnchor, constant: -2)
                ])

                stack.addArrangedSubview(assetView)
                NSLayoutConstraint.activate([
                    assetView.widthAnchor.constraint(equalToConstant: sizes.avatarSideLength),
                    assetView.heightAnchor.constraint(equalToConstant: sizes.avatarSideLength)
                ])
                
                computedWidth += sizes.avatarSideLength
            }
        }
        computedWidth += max(0, CGFloat(stack.arrangedSubviews.count - 1) * stack.spacing)

        let leadingStackMargin: CGFloat
        switch pillData.items.first {
        case .asset, .avatar:
            leadingStackMargin = sizes.avatarLeading
            computedWidth += sizes.avatarLeading + sizes.horizontalMargin
        default:
            leadingStackMargin = sizes.horizontalMargin
            computedWidth += 2 * sizes.horizontalMargin
        }
        
        let pillBackgroundView = UIView(frame: CGRect(x: 0,
                                        y: sizes.verticalMargin,
                                        width: computedWidth,
                                        height: sizes.pillBackgroundHeight))

        pillBackgroundView.addSubview(stack)
                
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: pillBackgroundView.leadingAnchor, constant: leadingStackMargin),
            stack.trailingAnchor.constraint(equalTo: pillBackgroundView.trailingAnchor, constant: -sizes.horizontalMargin),
            stack.topAnchor.constraint(equalTo: pillBackgroundView.topAnchor, constant: sizes.verticalMargin),
            stack.bottomAnchor.constraint(equalTo: pillBackgroundView.bottomAnchor, constant: -sizes.verticalMargin)
        ])
        
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
