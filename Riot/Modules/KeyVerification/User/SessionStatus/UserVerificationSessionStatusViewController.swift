// File created from ScreenTemplate
// $ createScreen.sh SessionStatus UserVerificationSessionStatus
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

import UIKit

final class UserVerificationSessionStatusViewController: UIViewController {
    
    // MARK: - Constants
    
    private enum Constants {
        static let verifyButtonCornerRadius: CGFloat = 8.0
        static let informationTextDefaultFont = UIFont.systemFont(ofSize: 15.0)
        static let informationTextBoldFont = UIFont.systemFont(ofSize: 15.0, weight: .medium)
        static let deviceNameFont = UIFont.systemFont(ofSize: 17.0, weight: .medium)
        static let deviceIdFont = UIFont.systemFont(ofSize: 15.0)
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var badgeImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var informationLabel: UILabel!
    
    @IBOutlet private weak var deviceStatusImageView: UIImageView!
    @IBOutlet private weak var deviceInformationLabel: UILabel!
    
    @IBOutlet private weak var untrustedSessionContainerView: UIView!
    @IBOutlet private weak var untrustedSessionInformationLabel: UILabel!
    @IBOutlet private weak var verifyButton: UIButton!
    @IBOutlet private weak var manuallyVerifyButton: UIButton!
    
    // MARK: Private

    private var viewModel: UserVerificationSessionStatusViewModelType!
    private var theme: Theme!
    private var keyboardAvoider: KeyboardAvoider?
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!

    // MARK: - Setup
    
    class func instantiate(with viewModel: UserVerificationSessionStatusViewModelType) -> UserVerificationSessionStatusViewController {
        let viewController = StoryboardScene.UserVerificationSessionStatusViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.                
        
        self.setupViews()
        self.vc_removeBackTitle()
        self.activityPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = MXKErrorAlertPresentation()
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        self.viewModel.viewDelegate = self
        self.viewModel.process(viewAction: .loadData)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.verifyButton.layer.cornerRadius = Constants.verifyButtonCornerRadius
        self.closeButton.layer.cornerRadius = self.closeButton.frame.size.width/2
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        self.view.backgroundColor = theme.headerBackgroundColor
        
        self.titleLabel.textColor = theme.textPrimaryColor
        self.closeButton.vc_setBackgroundColor(theme.headerTextSecondaryColor, for: .normal)
        
        self.informationLabel.textColor = theme.textPrimaryColor
        
        self.untrustedSessionInformationLabel.textColor = theme.textPrimaryColor
        self.verifyButton.vc_setBackgroundColor(theme.tintColor, for: .normal)
        
        theme.applyStyle(onButton: self.manuallyVerifyButton)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        self.closeButton.layer.masksToBounds = true
        self.verifyButton.layer.masksToBounds = true
        
        self.manuallyVerifyButton.setTitle(VectorL10n.userVerificationSessionDetailsVerifyActionCurrentUserManually, for: .normal)
    }

    private func render(viewState: UserVerificationSessionStatusViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .loaded(viewData: let sessionStatusViewData):
            self.renderLoaded(viewData: sessionStatusViewData)
        case .error(let error):
            self.render(error: error)
        }
    }
    
    private func renderLoading() {
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
    }
    
    private func renderLoaded(viewData: SessionStatusViewData) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        
        let badgeImage: UIImage
        let title: String
        
        self.untrustedSessionContainerView.isHidden = viewData.isDeviceTrusted
        
        self.manuallyVerifyButton.isHidden = !viewData.isCurrentUser
        
        if viewData.isDeviceTrusted {
            badgeImage = Asset.Images.encryptionTrusted.image
            title = VectorL10n.userVerificationSessionDetailsTrustedTitle
        } else {
            badgeImage = Asset.Images.encryptionWarning.image
            title = VectorL10n.userVerificationSessionDetailsUntrustedTitle
        }
        
        let unstrustedInformationText: String
        let verifyButtonTitle: String
        
        if viewData.isCurrentUser {
            unstrustedInformationText = VectorL10n.userVerificationSessionDetailsAdditionalInformationUntrustedCurrentUser
            verifyButtonTitle = VectorL10n.userVerificationSessionDetailsVerifyActionCurrentUser
        } else {
            unstrustedInformationText = VectorL10n.userVerificationSessionDetailsAdditionalInformationUntrustedOtherUser
            verifyButtonTitle = VectorL10n.userVerificationSessionDetailsVerifyActionOtherUser
        }
        
        self.badgeImageView.image = badgeImage
        self.titleLabel.text = title
        self.informationLabel.attributedText = self.buildInformationAttributedText(with: viewData)
        
        self.deviceStatusImageView.image = badgeImage
        self.deviceInformationLabel.attributedText = self.builDeviceInfoAttributedText(with: viewData)
        
        self.untrustedSessionInformationLabel.text = unstrustedInformationText
        self.verifyButton.setTitle(verifyButtonTitle, for: .normal)
    }
    
    private func render(error: Error) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: {
            
            if case UserVerificationSessionStatusViewModelError.deviceNotFound = error {
                self.viewModel.process(viewAction: .close)
            }
        })
    }
    
    private func buildUserInfoText(with userId: String, userDisplayName: String?) -> String {
        
        let userInfoText: String
        
        if let userDisplayName = userDisplayName {
            userInfoText = "\(userDisplayName) (\(userId))"
        } else {
            userInfoText = userId
        }
        
        return userInfoText
    }
    
    private func buildInformationAttributedText(with viewData: SessionStatusViewData) -> NSAttributedString {
        
        let informationAttributedText: NSMutableAttributedString = NSMutableAttributedString()
        
        let informationTextDefaultAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: self.theme.textPrimaryColor,
                                                                               .font: Constants.informationTextDefaultFont]
        
        let informationTextBoldAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: self.theme.textPrimaryColor,
                                                                            .font: Constants.informationTextBoldFont]
        
        let userInfoText = self.buildUserInfoText(with: viewData.userId, userDisplayName: viewData.userDisplayName)
        
        if viewData.isDeviceTrusted {
            
            if viewData.isCurrentUser {
                let informationAttributedStringPart1 = NSAttributedString(string: VectorL10n.userVerificationSessionDetailsInformationTrustedCurrentUser, attributes: informationTextDefaultAttributes)
                informationAttributedText.append(informationAttributedStringPart1)
            } else {
                let informationAttributedStringPart1 = NSAttributedString(string: VectorL10n.userVerificationSessionDetailsInformationTrustedOtherUserPart1, attributes: informationTextDefaultAttributes)
                let informationAttributedStringPart2 = NSAttributedString(string: userInfoText, attributes: informationTextBoldAttributes)
                let informationAttributedStringPart3 = NSAttributedString(string: VectorL10n.userVerificationSessionDetailsInformationTrustedOtherUserPart2, attributes: informationTextDefaultAttributes)
                
                informationAttributedText.append(informationAttributedStringPart1)
                informationAttributedText.append(informationAttributedStringPart2)
                informationAttributedText.append(informationAttributedStringPart3)
            }
            
        } else {
            if viewData.isCurrentUser {
                let informationAttributedStringPart1 = NSAttributedString(string: VectorL10n.userVerificationSessionDetailsInformationUntrustedCurrentUser, attributes: informationTextDefaultAttributes)
                informationAttributedText.append(informationAttributedStringPart1)
            } else {
                let informationAttributedStringPart1 = NSAttributedString(string: userInfoText, attributes: informationTextBoldAttributes)
                let informationAttributedStringPart2 = NSAttributedString(string: VectorL10n.userVerificationSessionDetailsInformationUntrustedOtherUser, attributes: informationTextDefaultAttributes)
                
                informationAttributedText.append(informationAttributedStringPart1)
                informationAttributedText.append(informationAttributedStringPart2)
            }
        }
        
        return informationAttributedText
    }
    
    private func builDeviceInfoAttributedText(with viewData: SessionStatusViewData) -> NSAttributedString {
        let deviceInfoAttributedText = NSMutableAttributedString()
        let deviceInfoAttributedTextPart1 = NSAttributedString(string: "\(viewData.deviceName) ", attributes: [.foregroundColor: self.theme.textPrimaryColor, .font: Constants.deviceNameFont])
        let deviceInfoAttributedTextPart2 = NSAttributedString(string: "(\(viewData.deviceId))", attributes: [.foregroundColor: self.theme.textSecondaryColor, .font: Constants.deviceIdFont])
        deviceInfoAttributedText.append(deviceInfoAttributedTextPart1)
        deviceInfoAttributedText.append(deviceInfoAttributedTextPart2)
        return deviceInfoAttributedText
    }
    
    // MARK: - Actions
    
    @IBAction private func closeButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .close)
    }
    
    @IBAction private func verifyButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .verify)
    }
    
    @IBAction private func manuallyVerifyButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .verifyManually)
    }
}


// MARK: - UserVerificationSessionStatusViewModelViewDelegate
extension UserVerificationSessionStatusViewController: UserVerificationSessionStatusViewModelViewDelegate {

    func userVerificationSessionStatusViewModel(_ viewModel: UserVerificationSessionStatusViewModelType, didUpdateViewState viewSate: UserVerificationSessionStatusViewState) {
        self.render(viewState: viewSate)
    }
}
