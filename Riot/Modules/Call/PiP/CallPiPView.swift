// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit
import Reusable

@objcMembers
class CallPiPView: UIView {
    
    private enum Constants {
        static let viewWidth: CGFloat = 90
        static let smallDotWidth: CGFloat = 8
        static let bigDotWidth: CGFloat = 10
        static let spaceBetweenDots: CGFloat = 4
        static let placeholderFontScale: CGFloat = 0.7
    }
    
    @IBOutlet private weak var bgView: UIView!
    @IBOutlet private weak var bgImageView: MXKImageView!
    
    @IBOutlet private weak var stackView: UIStackView!
    
    @IBOutlet private weak var mainCallAvatarImageView: MXKImageView! {
        didSet {
            mainCallAvatarImageView.clipsToBounds = true
            mainCallAvatarImageView.layer.cornerRadius = mainCallAvatarImageView.bounds.width/2
        }
    }
    @IBOutlet private weak var mainCallPauseIcon: UIImageView!
    
    @IBOutlet private weak var onHoldCallView: UIView!
    @IBOutlet private weak var onHoldCallAvatarImageView: MXKImageView! {
        didSet {
            onHoldCallAvatarImageView.clipsToBounds = true
            onHoldCallAvatarImageView.layer.cornerRadius = onHoldCallAvatarImageView.bounds.width/2
        }
    }
    @IBOutlet private weak var onHoldCallEffectView: UIVisualEffectView! {
        didSet {
            onHoldCallEffectView.clipsToBounds = true
            onHoldCallEffectView.layer.cornerRadius = onHoldCallEffectView.bounds.width/2
        }
    }
    
    @IBOutlet private weak var connectingView: DotsView! {
        didSet {
            connectingView.dotMinWidth = self.bounds.width * Constants.smallDotWidth/Constants.viewWidth
            connectingView.dotMaxWidth = self.bounds.width * Constants.bigDotWidth/Constants.viewWidth
            connectingView.interSpaceMargin = self.bounds.width * Constants.spaceBetweenDots/Constants.viewWidth
        }
    }
    
    private var theme: Theme = ThemeService.shared().theme
    private var session: MXSession!
    
    static func instantiate(withSession session: MXSession) -> CallPiPView {
        let view = self.loadFromNib()
        view.session = session
        return view
    }
    
    func configure(withCall mainCall: MXCall,
                   peer: MXUser?,
                   onHoldCall: MXCall?,
                   onHoldPeer: MXUser?) {
        switch mainCall.state {
        case .fledgling, .waitLocalMedia, .createOffer, .inviteSent, .ringing, .createAnswer, .connecting:
            stackView.isHidden = true
            connectingView.isHidden = false
            mainCallPauseIcon.isHidden = true
        default:
            connectingView.isHidden = true
            if mainCall.isVideoCall {
                bgView.isHidden = true
                stackView.isHidden = true
            } else {
                bgView.isHidden = false
                stackView.isHidden = false
            }
            mainCallPauseIcon.isHidden = !mainCall.isOnHold
            onHoldCallView.isHidden = onHoldCall == nil
        }
        
        let bgPlaceholder = placeholderImage(forPeer: peer,
                                             call: mainCall,
                                             imageView: bgImageView)
        let mainCallPlaceholder = placeholderImage(forPeer: peer,
                                                   call: mainCall,
                                                   imageView: mainCallAvatarImageView)
        
        bgImageView.contentMode = .scaleAspectFill
        mainCallAvatarImageView.contentMode = .scaleAspectFill
        onHoldCallAvatarImageView.contentMode = .scaleAspectFill
        
        if let avatarUrl = peer?.avatarUrl {
            bgImageView.mediaFolder = kMXMediaManagerAvatarThumbnailFolder
            bgImageView.enableInMemoryCache = true
            
            bgImageView.setImageURI(avatarUrl,
                                    withType: nil,
                                    andImageOrientation: .up,
                                    previewImage: bgPlaceholder,
                                    mediaManager: session.mediaManager)
            
            mainCallAvatarImageView.mediaFolder = kMXMediaManagerAvatarThumbnailFolder
            mainCallAvatarImageView.enableInMemoryCache = true
            
            mainCallAvatarImageView.setImageURI(avatarUrl,
                                                withType: nil,
                                                andImageOrientation: .up,
                                                previewImage: mainCallPlaceholder,
                                                mediaManager: session.mediaManager)
        } else {
            bgImageView.image = bgPlaceholder
            mainCallAvatarImageView.image = mainCallPlaceholder
        }
        
        let onHoldCallPlaceholder = placeholderImage(forPeer: onHoldPeer,
                                                     call: onHoldCall,
                                                     imageView: onHoldCallAvatarImageView)
        
        if let avatarUrl = onHoldPeer?.avatarUrl {
            onHoldCallAvatarImageView.mediaFolder = kMXMediaManagerAvatarThumbnailFolder
            onHoldCallAvatarImageView.enableInMemoryCache = true
            
            onHoldCallAvatarImageView.setImageURI(avatarUrl,
                                                  withType: nil,
                                                  andImageOrientation: .up,
                                                  previewImage: onHoldCallPlaceholder,
                                                  mediaManager: session.mediaManager)
        } else {
            onHoldCallAvatarImageView.image = onHoldCallPlaceholder
        }
    }
    
    private func placeholderImage(forPeer peer: MXUser?,
                                  call: MXCall?,
                                  imageView: MXKImageView) -> UIImage? {
        let fontSize = imageView.bounds.width * Constants.placeholderFontScale
        
        if let peer = peer {
            return AvatarGenerator.generateAvatar(forMatrixItem: peer.userId,
                                                  withDisplayName: peer.displayname,
                                                  size: imageView.bounds.width,
                                                  andFontSize: fontSize)
        } else if let room = call?.room {
            return AvatarGenerator.generateAvatar(forMatrixItem: room.roomId,
                                                  withDisplayName: room.summary.displayName,
                                                  size: imageView.bounds.width,
                                                  andFontSize: fontSize)
        }
        
        return MXKTools.paint(Asset.Images.placeholder.image,
                              with: theme.tintColor)
    }
    
}

extension CallPiPView: NibReusable {}

extension CallPiPView: Themable {
    
    func update(theme: Theme) {
        self.theme = theme
    }
    
}
