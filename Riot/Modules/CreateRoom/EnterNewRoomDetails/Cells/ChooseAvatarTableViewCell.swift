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

protocol ChooseAvatarTableViewCellDelegate: AnyObject {
    func chooseAvatarTableViewCellDidTapChooseAvatar(_ cell: ChooseAvatarTableViewCell, sourceView: UIView)
    func chooseAvatarTableViewCellDidTapRemoveAvatar(_ cell: ChooseAvatarTableViewCell)
}

class ChooseAvatarTableViewCell: UITableViewCell {

    @IBOutlet private weak var avatarImageView: UIImageView! {
        didSet {
            avatarImageView.layer.cornerRadius = avatarImageView.frame.width/2
        }
    }
    @IBOutlet private weak var chooseAvatarButton: UIButton!
    @IBOutlet private weak var removeAvatarButton: UIButton! {
        didSet {
            removeAvatarButton.imageView?.contentMode = .scaleAspectFit
        }
    }
    
    weak var delegate: ChooseAvatarTableViewCellDelegate?
    
    @IBAction private func chooseAvatarButtonTapped(_ sender: UIButton) {
        delegate?.chooseAvatarTableViewCellDidTapChooseAvatar(self, sourceView: sender)
    }

    @IBAction private func removeAvatarButtonTapped(_ sender: UIButton) {
        delegate?.chooseAvatarTableViewCellDidTapRemoveAvatar(self)
    }
    
    func configure(withViewModel viewModel: ChooseAvatarTableViewCellVM) {
        if let image = viewModel.avatarImage {
            avatarImageView.image = image
            removeAvatarButton.isHidden = false
        } else {
            avatarImageView.image = Asset.Images.captureAvatar.image
            removeAvatarButton.isHidden = true
        }
    }
    
}

extension ChooseAvatarTableViewCell: NibReusable {}

extension ChooseAvatarTableViewCell: Themable {
    
    func update(theme: Theme) {
        backgroundView = UIView()
        backgroundView?.backgroundColor = theme.backgroundColor
    }
    
}
