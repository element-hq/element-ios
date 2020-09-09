// 
// Copyright 2020 New Vector Ltd
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

class DirectoryRoomTableViewCell: UITableViewCell {
    
    @IBOutlet private weak var avatarImageView: MXKImageView! {
        didSet {
            avatarImageView.layer.cornerRadius = avatarImageView.frame.width/2
            avatarImageView.clipsToBounds = true
        }
    }
    @IBOutlet private weak var displaynameLabel: UILabel!
    @IBOutlet private weak var numberOfUsersLabel: UILabel!
    @IBOutlet private weak var topicLabel: UILabel!
    @IBOutlet private weak var joinButton: UIButton!
    @IBOutlet private weak var joinActivityIndicator: UIActivityIndicatorView!

    private weak var room: MXPublicRoom!
    private weak var session: MXSession!
    private var isJoined: Bool = false {
        didSet {
            joinButton.setTitle(isJoined ? VectorL10n.joined : VectorL10n.join, for: .normal)
            joinButton.isUserInteractionEnabled = !isJoined
            joinActivityIndicator.isHidden = true
            update(theme: ThemeService.shared().theme)
        }
    }

    func configure(withRoom room: MXPublicRoom, session: MXSession) {
        self.room = room
        self.session = session
        
        displaynameLabel.text = room.name
        if displaynameLabel.text == nil {
            displaynameLabel.text = room.aliases?.first
        }
        
        if room.numJoinedMembers > 0 {
            numberOfUsersLabel.isHidden = false
            numberOfUsersLabel.text = String(room.numJoinedMembers)
        } else {
            numberOfUsersLabel.isHidden = true
        }
        
        if let topic = room.topic {
            topicLabel.text = MXTools.stripNewlineCharacters(topic)
            topicLabel.isHidden = false
        } else {
            topicLabel.isHidden = true
        }
        
        let avatarImage = AvatarGenerator.generateAvatar(forMatrixItem: room.roomId, withDisplayName: displaynameLabel.text)
        
        if let avatarUrl = room.avatarUrl {
            avatarImageView.enableInMemoryCache = true
            
            avatarImageView.setImageURI(avatarUrl,
                                        withType: nil,
                                        andImageOrientation: .up,
                                        toFitViewSize: avatarImageView.frame.size,
                                        with: MXThumbnailingMethodCrop,
                                        previewImage: avatarImage,
                                        mediaManager: session.mediaManager)
        } else {
            avatarImageView.image = avatarImage
        }
        
        avatarImageView.contentMode = .scaleAspectFill
        
        guard let summary = session.roomSummary(withRoomId: room.roomId) else {
            isJoined = false
            return
        }
        isJoined = summary.membership == .join
        joinActivityIndicator.isHidden = true
    }
    
    @IBAction private func joinButtonTapped(_ sender: UIButton) {
        sender.setTitle(nil, for: .normal)
        joinActivityIndicator.isHidden = false
        session.joinRoom(room.roomId) { [weak self] (response) in
            guard let self = self else { return }
            switch response {
            case .success:
                self.isJoined = true
            default:
                self.isJoined = false
            }
        }
    }
    
}

extension DirectoryRoomTableViewCell: NibReusable {}

extension DirectoryRoomTableViewCell: Themable {
    
    func update(theme: Theme) {
        backgroundView = UIView()
        backgroundView?.backgroundColor = theme.backgroundColor
        
        displaynameLabel.textColor = theme.textPrimaryColor
        numberOfUsersLabel.textColor = theme.textSecondaryColor
        topicLabel.textColor = theme.textSecondaryColor
        
        if isJoined {
            joinButton.backgroundColor = theme.backgroundColor
            joinButton.tintColor = theme.textSecondaryColor
            joinButton.layer.borderWidth = 1.0
            joinButton.layer.borderColor = theme.textSecondaryColor.cgColor
        } else {
            joinButton.backgroundColor = theme.tintColor
            joinButton.tintColor = .white
            joinButton.layer.borderWidth = 0.0
            joinButton.layer.borderColor = nil
        }
    }
    
}
