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

final class KeyVerificationCellInnerContentView: UIView, NibLoadable {
    
    // MARK: - Constants
    
    private enum Constants {
        static let cornerRadius: CGFloat = 8.0
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var badgeImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    
    @IBOutlet private weak var otherUserInformationLabel: UILabel!
    
    @IBOutlet private weak var requestStatusLabel: UILabel!
    
    @IBOutlet private weak var buttonsContainerView: UIView!
    @IBOutlet private weak var acceptButton: RoundedButton!
    @IBOutlet private weak var declineButton: RoundedButton!
    
    // MARK: Public
    
    var isButtonsHidden: Bool {
        get {
            return self.acceptButton.isHidden && self.declineButton.isHidden
        }
        set {
            self.buttonsContainerView.isHidden = newValue
        }
    }
    
    var isRequestStatusHidden: Bool {
        get {
            return self.requestStatusLabel.isHidden
        }
        set {
            self.requestStatusLabel.isHidden = newValue
        }
    }
    
    var badgeImage: UIImage? {
        get {
            return self.badgeImageView.image
        }
        set {
            self.badgeImageView.image = newValue
        }
    }
    
    var title: String? {
        get {
            return self.titleLabel.text
        }
        set {
            self.titleLabel.text = newValue
        }
    }
    
    var otherUserInfo: String? {
        return self.otherUserInformationLabel.text
    }
    
    var requestStatusText: String? {
        get {
            return self.requestStatusLabel.text
        }
        set {
            self.requestStatusLabel.text = newValue
        }
    }
    
    var acceptActionHandler: (() -> Void)?
    
    var declineActionHandler: (() -> Void)?
    
    // MARK: - Setup
    
    static func instantiate() -> KeyVerificationCellInnerContentView {
        let view = KeyVerificationCellInnerContentView.loadFromNib()
        return view
    }
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.masksToBounds = true
        
        self.acceptButton.titleLabel?.adjustsFontSizeToFitWidth = true
        self.acceptButton.titleLabel?.minimumScaleFactor = 0.5
        self.acceptButton.titleLabel?.baselineAdjustment = .alignCenters
        self.acceptButton.setTitle(VectorL10n.keyVerificationTileRequestIncomingApprovalAccept, for: .normal)
        
        self.declineButton.titleLabel?.adjustsFontSizeToFitWidth = true
        self.declineButton.titleLabel?.minimumScaleFactor = 0.5
        self.declineButton.titleLabel?.baselineAdjustment = .alignCenters
        self.declineButton.actionStyle = .cancel
        self.declineButton.setTitle(VectorL10n.keyVerificationTileRequestIncomingApprovalDecline, for: .normal)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.cornerRadius = Constants.cornerRadius
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        self.backgroundColor = theme.colors.system
        self.titleLabel.textColor = theme.textPrimaryColor
        self.otherUserInformationLabel.textColor = theme.textSecondaryColor
        
        self.acceptButton.update(theme: theme)
        self.declineButton.update(theme: theme)
    }
    
    func updateSenderInfo(with userId: String, userDisplayName: String?) {
        self.otherUserInformationLabel.text = self.buildUserInfoText(with: userId, userDisplayName: userDisplayName)
    }
    
    // MARK: - Private
    
    private func buildUserInfoText(with userId: String, userDisplayName: String?) -> String {
        
        let userInfoText: String
        
        if let userDisplayName = userDisplayName {
            userInfoText = "\(userId) (\(userDisplayName))"
        } else {
            userInfoText = userId
        }
        
        return userInfoText
    }
    
    // MARK: - Action
    
    @IBAction private func declineButtonAction(_ sender: Any) {
        self.declineActionHandler?()
    }
    
    @IBAction private func acceptButtonAction(_ sender: Any) {
        self.acceptActionHandler?()
    }
}
