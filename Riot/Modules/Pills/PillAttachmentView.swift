// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

/// Base view class for mention Pills.
@available(iOS 15.0, *)
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

        var computedWidth: CGFloat = 0
        for item in pillData.items {
            switch item {
            case .text(let string):
                let label = UILabel(frame: .zero)
                label.text = string
                label.font = pillData.font
                label.textColor = pillData.isHighlighted ? theme.baseTextPrimaryColor : theme.textPrimaryColor
                label.translatesAutoresizingMaskIntoConstraints = false
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
                
            case .asset(let name, let parameters):
                let assetView = UIView(frame: CGRect(x: 0, y: 0, width: sizes.avatarSideLength, height: sizes.avatarSideLength))
                assetView.backgroundColor = parameters.backgroundColor?.uiColor
                assetView.layer.cornerRadius = sizes.avatarSideLength / 2
                assetView.isUserInteractionEnabled = false
                assetView.translatesAutoresizingMaskIntoConstraints = false

                let imageView = UIImageView(frame: .zero)
                imageView.image = ImageAsset(name: name).image.withRenderingMode(UIImage.RenderingMode(rawValue: parameters.rawRenderingMode) ?? .automatic)
                imageView.tintColor = parameters.tintColor?.uiColor ?? theme.baseIconPrimaryColor
                imageView.contentMode = .scaleAspectFit
                                
                assetView.vc_addSubViewMatchingParent(imageView, withInsets: UIEdgeInsets(top: parameters.padding, left: parameters.padding, bottom: -parameters.padding, right: -parameters.padding))

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
        
        computedWidth = min(pillData.maxWidth, computedWidth)
        
        let pillBackgroundView = UIView(frame: CGRect(x: 0,
                                                      y: sizes.verticalMargin,
                                                      width: computedWidth,
                                                      height: sizes.pillBackgroundHeight))

        pillBackgroundView.vc_addSubViewMatchingParent(stack, withInsets: UIEdgeInsets(top: sizes.verticalMargin, left: leadingStackMargin, bottom: -sizes.verticalMargin, right: -sizes.horizontalMargin))
        
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
