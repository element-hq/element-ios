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

final class KeyVerificationCellInnerContentView: UIView, NibLoadable {
    // MARK: - Constants
    
    private enum Constants {
        static let cornerRadius: CGFloat = 8.0
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private var badgeImageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    
    @IBOutlet private var otherUserInformationLabel: UILabel!
    
    @IBOutlet private var requestStatusLabel: UILabel!
    
    @IBOutlet private var buttonsContainerView: UIView!
    @IBOutlet private var acceptButton: RoundedButton!
    @IBOutlet private var declineButton: RoundedButton!
    
    // MARK: Public
    
    var isButtonsHidden: Bool {
        get {
            acceptButton.isHidden && declineButton.isHidden
        }
        set {
            buttonsContainerView.isHidden = newValue
        }
    }
    
    var isRequestStatusHidden: Bool {
        get {
            requestStatusLabel.isHidden
        }
        set {
            requestStatusLabel.isHidden = newValue
        }
    }
    
    var badgeImage: UIImage? {
        get {
            badgeImageView.image
        }
        set {
            badgeImageView.image = newValue
        }
    }
    
    var title: String? {
        get {
            titleLabel.text
        }
        set {
            titleLabel.text = newValue
        }
    }
    
    var otherUserInfo: String? {
        otherUserInformationLabel.text
    }
    
    var requestStatusText: String? {
        get {
            requestStatusLabel.text
        }
        set {
            requestStatusLabel.text = newValue
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
        
        layer.masksToBounds = true
        
        acceptButton.titleLabel?.adjustsFontSizeToFitWidth = true
        acceptButton.titleLabel?.minimumScaleFactor = 0.5
        acceptButton.titleLabel?.baselineAdjustment = .alignCenters
        acceptButton.setTitle(VectorL10n.keyVerificationTileRequestIncomingApprovalAccept, for: .normal)
        
        declineButton.titleLabel?.adjustsFontSizeToFitWidth = true
        declineButton.titleLabel?.minimumScaleFactor = 0.5
        declineButton.titleLabel?.baselineAdjustment = .alignCenters
        declineButton.actionStyle = .cancel
        declineButton.setTitle(VectorL10n.keyVerificationTileRequestIncomingApprovalDecline, for: .normal)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = Constants.cornerRadius
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        backgroundColor = theme.headerBackgroundColor
        titleLabel.textColor = theme.textPrimaryColor
        otherUserInformationLabel.textColor = theme.textSecondaryColor
        
        acceptButton.update(theme: theme)
        declineButton.update(theme: theme)
    }
    
    func updateSenderInfo(with userId: String, userDisplayName: String?) {
        otherUserInformationLabel.text = buildUserInfoText(with: userId, userDisplayName: userDisplayName)
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
        declineActionHandler?()
    }
    
    @IBAction private func acceptButtonAction(_ sender: Any) {
        acceptActionHandler?()
    }
}
