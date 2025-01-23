// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
    @IBOutlet private weak var rootMessageContentTextView: UITextView!
    @IBOutlet private weak var lastMessageTimeLabel: UILabel!
    @IBOutlet private weak var summaryView: ThreadSummaryView!
    @IBOutlet private weak var notificationStatusView: ThreadNotificationStatusView!
    
    private static var usernameColorGenerator = UserNameColorGenerator()

    override func awakeFromNib() {
        super.awakeFromNib()
        
        separatorInset = Constants.separatorInset
    }
    
    func configure(withModel model: ThreadModel) {
        if let rootAvatar = model.rootMessageSenderAvatar {
            rootMessageAvatarView.fill(with: rootAvatar)
        } else {
            rootMessageAvatarView.avatarImageView.image = nil
        }
        configuredSenderId = model.rootMessageSenderUserId
        configuredRootMessageRedacted = model.rootMessageRedacted
        updateRootMessageSenderColor()
        rootMessageSenderLabel.text = model.rootMessageSenderDisplayName
        if let rootMessageText = model.rootMessageText {
            updateRootMessageContentAttributes(rootMessageText, color: rootMessageColor)
        } else {
            rootMessageContentTextView.attributedText = nil
        }
        lastMessageTimeLabel.text = model.lastMessageTime
        if let summaryModel = model.summaryModel {
            summaryView.configure(withModel: summaryModel)
        }
        notificationStatusView.status = model.notificationStatus
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
        rootMessageContentTextView.attributedText = mutable
    }

}

extension ThreadTableViewCell: NibReusable {}

extension ThreadTableViewCell: Themable {
    
    func update(theme: Theme) {
        self.theme = theme
        Self.usernameColorGenerator.update(theme: theme)
        updateRootMessageSenderColor()
        rootMessageAvatarView.backgroundColor = .clear
        if let attributedText = rootMessageContentTextView.attributedText {
            updateRootMessageContentAttributes(attributedText, color: rootMessageColor)
        }
        lastMessageTimeLabel.textColor = theme.colors.secondaryContent
        summaryView.update(theme: theme)
        summaryView.backgroundColor = .clear
        notificationStatusView.update(theme: theme)
    }
    
}
