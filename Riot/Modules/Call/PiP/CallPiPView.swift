// 
// Copyright 2021 New Vector Ltd
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
import Reusable

@objcMembers
class CallPiPView: UIView {
    
    private enum Constants {
        static let viewWidth: CGFloat = 90
        static let smallDotWidth: CGFloat = 8
        static let bigDotWidth: CGFloat = 10
        static let spaceBetweenDots: CGFloat = 4
    }
    
    @IBOutlet private weak var bgImageView: MXKImageView!
    
    @IBOutlet private weak var stackView: UIStackView!
    
    @IBOutlet private weak var mainCallAvatarImageView: MXKImageView!
    
    @IBOutlet private weak var onHoldCallView: UIView!
    @IBOutlet private weak var onHoldCallAvatarImageView: MXKImageView!
    
    @IBOutlet private weak var connectingView: DotsView! {
        didSet {
            connectingView.dotMinWidth = self.bounds.width * Constants.smallDotWidth/Constants.viewWidth
            connectingView.dotMaxWidth = self.bounds.width * Constants.bigDotWidth/Constants.viewWidth
            connectingView.interSpaceMargin = self.bounds.width * Constants.spaceBetweenDots/Constants.viewWidth
        }
    }
    
    private lazy var defaultProfileImage: UIImage = {
        return Bundle.mxk_imageFromMXKAssetsBundle(withName: "default-profile")
    }()
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
        case .connected:
            connectingView.isHidden = true
            stackView.isHidden = false
            onHoldCallView.isHidden = onHoldCall == nil
        default:
            break
        }
        
        if let avatarUrl = peer?.avatarUrl {
            bgImageView.mediaFolder = kMXMediaManagerAvatarThumbnailFolder
            bgImageView.enableInMemoryCache = true
            
            bgImageView.setImageURI(avatarUrl,
                                    withType: nil,
                                    andImageOrientation: .up,
                                    toFitViewSize: bgImageView.bounds.size,
                                    with: MXThumbnailingMethodCrop,
                                    previewImage: defaultProfileImage,
                                    mediaManager: session.mediaManager)
            
            mainCallAvatarImageView.mediaFolder = kMXMediaManagerAvatarThumbnailFolder
            mainCallAvatarImageView.enableInMemoryCache = true
            
            mainCallAvatarImageView.setImageURI(avatarUrl,
                                                withType: nil,
                                                andImageOrientation: .up,
                                                toFitViewSize: bgImageView.bounds.size,
                                                with: MXThumbnailingMethodCrop,
                                                previewImage: defaultProfileImage,
                                                mediaManager: session.mediaManager)
        } else {
            bgImageView.image = defaultProfileImage
            mainCallAvatarImageView.image = defaultProfileImage
        }
        
        if let avatarUrl = onHoldPeer?.avatarUrl {
            onHoldCallAvatarImageView.mediaFolder = kMXMediaManagerAvatarThumbnailFolder
            onHoldCallAvatarImageView.enableInMemoryCache = true
            
            onHoldCallAvatarImageView.setImageURI(avatarUrl,
                                                  withType: nil,
                                                  andImageOrientation: .up,
                                                  toFitViewSize: bgImageView.bounds.size,
                                                  with: MXThumbnailingMethodCrop,
                                                  previewImage: defaultProfileImage,
                                                  mediaManager: session.mediaManager)
        } else {
            onHoldCallAvatarImageView.image = defaultProfileImage
        }
    }
    
}

extension CallPiPView: NibReusable {}
