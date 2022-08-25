/*
 Copyright 2020 New Vector Ltd
 
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

struct UserVerificationSessionStatusViewData {
    let deviceId: String
    let sessionName: String
    let isTrusted: Bool
}

final class UserVerificationSessionStatusCell: UITableViewCell, NibReusable, Themable {
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private var statusImageView: UIImageView!
    @IBOutlet private var sessionNameLabel: UILabel!
    @IBOutlet private var statusTextLabel: UILabel!
    
    // MARK: Private
    
    private var viewData: UserVerificationSessionStatusViewData?
    private var theme: Theme?
    
    // MARK: - Public
    
    func fill(viewData: UserVerificationSessionStatusViewData) {
        self.viewData = viewData
        
        let statusText: String
        let statusImage: UIImage
        
        if viewData.isTrusted {
            statusImage = Asset.Images.encryptionTrusted.image
            statusText = VectorL10n.userVerificationSessionsListSessionTrusted
        } else {
            statusImage = Asset.Images.encryptionWarning.image
            statusText = VectorL10n.userVerificationSessionsListSessionUntrusted
        }
        
        statusImageView.image = statusImage
        statusTextLabel.text = statusText
        sessionNameLabel.text = viewData.sessionName
        
        updateStatusTextColor()
    }
    
    func update(theme: Theme) {
        self.theme = theme
        backgroundColor = theme.headerBackgroundColor
        sessionNameLabel.textColor = theme.textPrimaryColor
        updateStatusTextColor()
    }
    
    // MARK: - Private
    
    private func updateStatusTextColor() {
        guard let viewData = viewData, let theme = theme else {
            return
        }
        statusTextLabel.textColor = viewData.isTrusted ? theme.tintColor : theme.warningColor
    }
}
