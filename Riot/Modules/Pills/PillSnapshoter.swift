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

// TODO: replace this with directly creating NSAttributedString with both link and attachment (removes weird interaction between two objects here)
@objcMembers class PillTextAttachment: NSTextAttachment {
    convenience init(withSession session: MXSession, url: NSURL, andRoomMember roomMember: MXRoomMember) {
        self.init()
        
        let image = PillSnapshoter.snapshot(withSession: session, andRoomMember: roomMember)
        self.image = image
        // FIXME: handle vertical offset better
        self.bounds = CGRect(x: 0.0, y: -5.0, width: image.size.width * 0.3, height: image.size.height * 0.3)
    }
}

@objcMembers class PillSnapshoter: NSObject {
    static func mentionPill(withSession session: MXSession, url: NSURL, andRoomMember roomMember: MXRoomMember) -> NSAttributedString {
        let attachment = PillTextAttachment(withSession: session, url: url, andRoomMember: roomMember)
        let string = NSAttributedString(attachment: attachment)
        let mutable = NSMutableAttributedString(attributedString: string)
        mutable.addAttribute(.link, value: url, range: .init(location: 0, length: mutable.length))
        return mutable
    }
    
    static func snapshot(withSession session: MXSession, andRoomMember roomMember: MXRoomMember) -> UIImage {
        let view = snapshotView(withSession: session, andRoomMember: roomMember)
        let rect: CGRect = view.frame

        UIGraphicsBeginImageContext(rect.size)
        let context: CGContext = UIGraphicsGetCurrentContext()!
        view.layer.render(in: context)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return img!
    }
    
    // TODO: Improve how image scale is handled
    // TODO: Implement a solution with image cache to increase performance
    private static func snapshotView(withSession session: MXSession, andRoomMember roomMember: MXRoomMember) -> UIView {
        let label = UILabel(frame: .zero)
        label.text = roomMember.displayname
        label.font = ThemeService.shared().theme.fonts.body.withSize(ThemeService.shared().theme.fonts.body.pointSize * 2.0)
        label.textColor = ThemeService.shared().theme.textPrimaryColor
        let labelSize = label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                  height: CGFloat.greatestFiniteMagnitude))
        label.frame = CGRect(x: 52 + 16, y: 0, width: labelSize.width, height: 60)
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: labelSize.width + 16 + 52 + 16, height: 60))
        
        // FIXME: handle avatar not being in cache at snapshot time
        let imageView = MXKImageView(frame: CGRect(x: 8, y: 4, width: 60, height: 60))
        imageView.setImageURI(roomMember.avatarUrl,
                              withType: nil,
                              andImageOrientation: .up,
                              toFitViewSize: imageView.frame.size,
                              with: MXThumbnailingMethodCrop,
                              previewImage: Asset.Images.userIcon.image,
                              mediaManager: session.mediaManager)
        imageView.clipsToBounds = true
        imageView.frame = CGRect(x: 8, y: 4, width: 52, height: 52)
        imageView.layer.cornerRadius = 26.0
        view.addSubview(imageView)

        view.addSubview(label)
        
        view.backgroundColor = ThemeService.shared().theme.secondaryCircleButtonBackgroundColor
        view.layer.cornerRadius = 30
        
        return view
    }
}
