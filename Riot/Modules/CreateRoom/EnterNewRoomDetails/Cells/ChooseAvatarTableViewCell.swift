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
}

class ChooseAvatarTableViewCell: UITableViewCell {

    @IBOutlet private weak var avatarImageView: UIImageView! {
        didSet {
            avatarImageView.layer.cornerRadius = avatarImageView.frame.width/2
        }
    }
    @IBOutlet private weak var chooseAvatarButton: UIButton!
    
    weak var delegate: ChooseAvatarTableViewCellDelegate?
    
    @IBAction private func chooseAvatarButtonTapped(_ sender: UIButton) {
        delegate?.chooseAvatarTableViewCellDidTapChooseAvatar(self, sourceView: sender)
    }
    
    func configure(withViewModel viewModel: ChooseAvatarTableViewCellVM) {
        avatarImageView.image = viewModel.avatarImage
    }
    
}

extension ChooseAvatarTableViewCell: NibReusable {}

extension ChooseAvatarTableViewCell: Themable {
    
    func update(theme: Theme) {
        backgroundView = UIView()
        backgroundView?.backgroundColor = theme.backgroundColor
        avatarImageView.backgroundColor = theme.tintColor
    }
    
}
