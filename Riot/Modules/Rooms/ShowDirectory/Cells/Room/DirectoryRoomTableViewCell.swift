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

protocol DirectoryRoomTableViewCellDelegate: AnyObject {
    func directoryRoomTableViewCellDidTapJoin(_ cell: DirectoryRoomTableViewCell)
}

class DirectoryRoomTableViewCell: UITableViewCell {
    
    @IBOutlet private weak var avatarImageView: MXKImageView! {
        didSet {
            avatarImageView.layer.cornerRadius = avatarImageView.frame.width/2
        }
    }
    
    @IBOutlet private weak var numberOfUsersIcon: UIImageView!
    @IBOutlet private weak var displaynameLabel: UILabel!
    @IBOutlet private weak var numberOfUsersLabel: UILabel!
    @IBOutlet private weak var topicLabel: UILabel!
    @IBOutlet private weak var joinButton: UIButton!
    @IBOutlet private weak var joinActivityIndicator: UIActivityIndicatorView!
    
    weak var delegate: DirectoryRoomTableViewCellDelegate?

    private var viewModel: DirectoryRoomTableViewCellVM!
    var indexPath: IndexPath!
    
    func startJoining() {
        joinButton.setTitle(nil, for: .normal)
        joinActivityIndicator.isHidden = false
        joinActivityIndicator.startAnimating()
    }
    
    func configure(withViewModel viewModel: DirectoryRoomTableViewCellVM) {
        //  keep viewModel
        self.viewModel = viewModel
        
        let attributedString = NSMutableAttributedString(string: viewModel.title!)

        if let range = viewModel.title!.range(of: "[TG]") {
            if range.lowerBound == viewModel.title!.startIndex {
                let imageAttachment = NSTextAttachment()
                imageAttachment.image = UIImage(named: "chatimg")?.resize(targetSize: CGSize(width: 15, height: 15))
                
                // Adjust the bounds and baselineOffset for proper alignment
                let imageSize = imageAttachment.image?.size ?? CGSize(width: 20, height: 20) // Set a default size if image is not available
                let yOffset = (displaynameLabel.font.capHeight - imageSize.height) / 2.0
                imageAttachment.bounds = CGRect(x: 0, y: yOffset, width: imageSize.width, height: imageSize.height)
                
                let imageString = NSAttributedString(attachment: imageAttachment)
                attributedString.replaceCharacters(in: NSRange(range, in: viewModel.title!), with: imageString)
            }
        }
        if let range = viewModel.title!.range(of: "$") {
            if range.lowerBound == viewModel.title!.startIndex {
                let imageAttachment = NSTextAttachment()
                imageAttachment.image = UIImage(named: "dollar")?.resize(targetSize: CGSize(width: 15, height: 15))
                
                // Adjust the bounds and baselineOffset for proper alignment
                let imageSize = imageAttachment.image?.size ?? CGSize(width: 20, height: 20) // Set a default size if image is not available
                let yOffset = (displaynameLabel.font.capHeight - imageSize.height) / 2.0
                imageAttachment.bounds = CGRect(x: 0, y: yOffset, width: imageSize.width, height: imageSize.height)
                let spaceString = NSAttributedString(string: " ", attributes: [NSAttributedString.Key.kern: 2.0])
                let combinedString = NSMutableAttributedString()
                let imageString = NSAttributedString(attachment: imageAttachment)
                combinedString.append(imageString)
                combinedString.append(spaceString)
                combinedString.append(NSAttributedString(string: viewModel.title?.replacingOccurrences(of: "$", with: "") ?? ""))
                attributedString.replaceCharacters(in: NSRange(range, in: viewModel.title!), with: combinedString)
            }
        }
        displaynameLabel.attributedText = attributedString

        
        let canShowNumberOfUsers = viewModel.numberOfUsers > 0
        
        numberOfUsersLabel.text = canShowNumberOfUsers ? String(viewModel.numberOfUsers) : nil
        numberOfUsersLabel.isHidden = !canShowNumberOfUsers
        numberOfUsersIcon.isHidden = !canShowNumberOfUsers
        
        if let subtitle = viewModel.subtitle {
            topicLabel.text = subtitle
            topicLabel.isHidden = false
        } else {
            topicLabel.isHidden = true
        }
        
        viewModel.setAvatar(in: avatarImageView)
        
        if viewModel.isJoined {
            joinButton.setTitle(VectorL10n.joined, for: .normal)
            joinButton.isUserInteractionEnabled = false
        } else {
            joinButton.setTitle(VectorL10n.join, for: .normal)
            joinButton.isUserInteractionEnabled = true
        }
        joinActivityIndicator.stopAnimating()
        joinActivityIndicator.isHidden = true
        update(theme: ThemeService.shared().theme)
    }
    
    @IBAction private func joinButtonTapped(_ sender: UIButton) {
        delegate?.directoryRoomTableViewCellDidTapJoin(self)
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
        
        if let viewModel = viewModel, viewModel.isJoined {
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
