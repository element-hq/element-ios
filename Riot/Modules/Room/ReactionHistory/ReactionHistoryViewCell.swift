/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit
import Reusable

final class ReactionHistoryViewCell: UITableViewCell, NibReusable, Themable {

    // MARK: - Properties
    
    @IBOutlet private weak var reactionLabel: UILabel!
    @IBOutlet private weak var userDisplayNameLabel: UILabel!
    @IBOutlet private weak var timestampLabel: UILabel!
    
    // MARK: - Public
    
    func fill(with viewData: ReactionHistoryViewData) {
        self.reactionLabel.text = viewData.reaction
        self.userDisplayNameLabel.text = viewData.userDisplayName
        self.timestampLabel.text = viewData.dateString
    }
    
    func update(theme: Theme) {
        self.backgroundColor = theme.backgroundColor
        self.reactionLabel.textColor = theme.textPrimaryColor
        self.userDisplayNameLabel.textColor = theme.textPrimaryColor
        self.timestampLabel.textColor = theme.textSecondaryColor
    }
}
