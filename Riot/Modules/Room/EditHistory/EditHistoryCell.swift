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

final class EditHistoryCell: UITableViewCell, NibReusable, Themable {
    // MARK: - Properties
    
    @IBOutlet private var timestampLabel: UILabel!
    @IBOutlet private var messageLabel: UILabel!
    
    // MARK: - Public
    
    func fill(with timeString: String, and attributedMessage: NSAttributedString) {
        timestampLabel.text = timeString
        messageLabel.attributedText = attributedMessage
    }
    
    func update(theme: Theme) {
        backgroundColor = theme.backgroundColor
        timestampLabel.textColor = theme.textSecondaryColor
    }
}
