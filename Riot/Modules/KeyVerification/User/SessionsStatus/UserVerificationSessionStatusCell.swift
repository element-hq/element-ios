/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit
import Reusable

struct UserVerificationSessionStatusViewData {
    let deviceId: String
    let sessionName: String
    let isTrusted: Bool
}

final class UserVerificationSessionStatusCell: UITableViewCell, NibReusable, Themable {

    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var statusImageView: UIImageView!
    @IBOutlet private weak var sessionNameLabel: UILabel!
    @IBOutlet private weak var statusTextLabel: UILabel!
    
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
        
        self.statusImageView.image = statusImage
        self.statusTextLabel.text = statusText
        self.sessionNameLabel.text = viewData.sessionName
        
        self.updateStatusTextColor()
    }
    
    func update(theme: Theme) {
        self.theme = theme
        self.backgroundColor = theme.colors.system
        self.sessionNameLabel.textColor = theme.textPrimaryColor
        self.updateStatusTextColor()
    }
    
    // MARK: - Private
    
    private func updateStatusTextColor() {
        guard let viewData = self.viewData, let theme = self.theme else {
            return
        }
        self.statusTextLabel.textColor = viewData.isTrusted ? theme.tintColor : theme.warningColor
    }
}
