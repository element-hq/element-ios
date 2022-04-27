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

@objcMembers class PillTextAttachment: NSTextAttachment {
    var roomMember: MXRoomMember?
    var alpha: CGFloat = 1.0
    
    convenience init(withRoomMember roomMember: MXRoomMember) {
        self.init(data: nil, ofType: "im.vector.app.pills")
        let image = PillSnapshoter.snapshotView(forRoomMember: roomMember)
        self.roomMember = roomMember
        // FIXME: handle vertical offset better
        self.bounds = CGRect(x: 0.0, y: -6.5, width: image.frame.width, height: image.frame.height)
    }
}

@objcMembers class PillSnapshoter: NSObject {
    private enum Constants {
        static let commonVerticalMargin: CGFloat = 1.0
        static let commonHorizontalMargin: CGFloat = 4.0
        static let avatarSideLength: CGFloat = 16.0
        static let pillBackgroundHeight: CGFloat = avatarSideLength + 2 * commonVerticalMargin
        static let displaynameLabelLeading: CGFloat = avatarSideLength + 2 * commonHorizontalMargin
        static let pillHeight: CGFloat = pillBackgroundHeight + 2 * commonVerticalMargin
        static let displaynameLabelTrailing: CGFloat = 1 * commonHorizontalMargin
        static let totalWidthWithoutLabel: CGFloat = displaynameLabelLeading + displaynameLabelTrailing
    }
    
    static func mentionPill(withRoomMember roomMember: MXRoomMember, andUrl url: URL) -> NSAttributedString {
        let attachment = PillTextAttachment(withRoomMember: roomMember)
        let string = NSAttributedString(attachment: attachment)
        let mutable = NSMutableAttributedString(attributedString: string)
        mutable.addAttribute(.link, value: url, range: .init(location: 0, length: mutable.length))
        return mutable
    }
    
    static func snapshotView(forRoomMember roomMember: MXRoomMember) -> PillAttachmentView {
        let label = UILabel(frame: .zero)
        label.text = roomMember.displayname
        label.font = ThemeService.shared().theme.fonts.body.withSize(ThemeService.shared().theme.fonts.body.pointSize * 0.7)
        label.textColor = ThemeService.shared().theme.textPrimaryColor
        let labelSize = label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                  height: CGFloat.greatestFiniteMagnitude))
        label.frame = CGRect(x: Constants.displaynameLabelLeading,
                             y: 0,
                             width: labelSize.width,
                             height: Constants.pillBackgroundHeight)
        
        let view = UIView(frame: CGRect(x: 0,
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
        view.addSubview(imageView)
        view.addSubview(label)

        view.backgroundColor = ThemeService.shared().theme.secondaryCircleButtonBackgroundColor
        view.layer.cornerRadius = Constants.pillBackgroundHeight / 2.0

        let pillView = PillAttachmentView(frame: CGRect(x: 0,
                                              y: 0,
                                              width: labelSize.width + Constants.totalWidthWithoutLabel,
                                              height: Constants.pillHeight))
        pillView.addSubview(view)

        return pillView
    }
}
