// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
