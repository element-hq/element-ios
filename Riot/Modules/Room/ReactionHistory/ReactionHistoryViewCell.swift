/*
 Copyright 2019 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
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
