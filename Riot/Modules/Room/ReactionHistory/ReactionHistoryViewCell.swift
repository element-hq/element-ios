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

import Reusable
import UIKit

final class ReactionHistoryViewCell: UITableViewCell, NibReusable, Themable {
    // MARK: - Properties
    
    @IBOutlet private var reactionLabel: UILabel!
    @IBOutlet private var userDisplayNameLabel: UILabel!
    @IBOutlet private var timestampLabel: UILabel!
    
    // MARK: - Public
    
    func fill(with viewData: ReactionHistoryViewData) {
        reactionLabel.text = viewData.reaction
        userDisplayNameLabel.text = viewData.userDisplayName
        timestampLabel.text = viewData.dateString
    }
    
    func update(theme: Theme) {
        backgroundColor = theme.backgroundColor
        reactionLabel.textColor = theme.textPrimaryColor
        userDisplayNameLabel.textColor = theme.textPrimaryColor
        timestampLabel.textColor = theme.textSecondaryColor
    }
}
