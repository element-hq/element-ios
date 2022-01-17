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

class ThreadTableViewCell: UITableViewCell {
    
    private enum Constants {
        static let separatorInset: UIEdgeInsets = UIEdgeInsets(top: 0, left: 56, bottom: 0, right: 0)
    }

    private var theme: Theme = ThemeService.shared().theme
    private var configuredSenderId: String?
    private var configuredRootMessageRedacted: Bool = false

    private var rootMessageColor: UIColor {
        return configuredRootMessageRedacted ?
            theme.colors.secondaryContent :
            theme.colors.primaryContent
    }
    
    @IBOutlet private weak var rootMessageAvatarView: UserAvatarView!
    @IBOutlet private weak var rootMessageSenderLabel: UILabel!
    @IBOutlet private weak var rootMessageContentLabel: UILabel!
    @IBOutlet private weak var lastMessageTimeLabel: UILabel!
    @IBOutlet private weak var summaryView: ThreadSummaryView!
    
    private static var usernameColorGenerator: UserNameColorGenerator = {
        let generator = UserNameColorGenerator()
        return generator
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        
        separatorInset = Constants.separatorInset
    }
    
    func configure(withViewModel viewModel: ThreadViewModel) {
        if let rootAvatar = viewModel.rootMessageSenderAvatar {
            rootMessageAvatarView.fill(with: rootAvatar)
        } else {
            rootMessageAvatarView.avatarImageView.image = nil
        }
        configuredSenderId = viewModel.rootMessageSenderUserId
        configuredRootMessageRedacted = viewModel.rootMessageRedacted
        updateRootMessageSenderColor()
        rootMessageSenderLabel.text = viewModel.rootMessageSenderDisplayName
        if let rootMessageText = viewModel.rootMessageText {
            updateRootMessageContentAttributes(rootMessageText, color: rootMessageColor)
        } else {
            rootMessageContentLabel.attributedText = nil
        }
        lastMessageTimeLabel.text = viewModel.lastMessageTime
        if let summaryViewModel = viewModel.summaryViewModel {
            summaryView.configure(withViewModel: summaryViewModel)
        }
    }

    private func updateRootMessageSenderColor() {
        if let senderUserId = configuredSenderId {
            rootMessageSenderLabel.textColor = Self.usernameColorGenerator.color(from: senderUserId)
        } else {
            rootMessageSenderLabel.textColor = Self.usernameColorGenerator.defaultColor
        }
    }

    private func updateRootMessageContentAttributes(_ string: NSAttributedString, color: UIColor) {
        let mutable = NSMutableAttributedString(attributedString: string)
        mutable.addAttributes([
            .foregroundColor: color
        ], range: NSRange(location: 0, length: mutable.length))
        rootMessageContentLabel.attributedText = mutable
    }

}

extension ThreadTableViewCell: NibReusable {}

extension ThreadTableViewCell: Themable {
    
    func update(theme: Theme) {
        self.theme = theme
        Self.usernameColorGenerator.defaultColor = theme.colors.primaryContent
        Self.usernameColorGenerator.userNameColors = theme.colors.namesAndAvatars
        updateRootMessageSenderColor()
        rootMessageAvatarView.backgroundColor = .clear
        if let attributedText = rootMessageContentLabel.attributedText {
            updateRootMessageContentAttributes(attributedText, color: rootMessageColor)
        }
        lastMessageTimeLabel.textColor = theme.colors.secondaryContent
        summaryView.update(theme: theme)
        summaryView.backgroundColor = .clear
    }
    
}
