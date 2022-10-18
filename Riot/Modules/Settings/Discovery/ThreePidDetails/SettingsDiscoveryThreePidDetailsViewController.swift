// File created from ScreenTemplate
// $ createScreen.sh Details SettingsDiscoveryThreePidDetails
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

final class SettingsDiscoveryThreePidDetailsViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var threePidBackgroundView: UIView!
    @IBOutlet private weak var threePidTitleLabel: UILabel!
    @IBOutlet private weak var threePidAdressLabel: UILabel!
    @IBOutlet private weak var operationButton: UIButton!
    @IBOutlet private weak var informationLabel: UILabel!
    
    // MARK: Private

    private var viewModel: SettingsDiscoveryThreePidDetailsViewModelType!
    private var theme: Theme!
    private var keyboardAvoider: KeyboardAvoider?
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    private weak var presentedAlertController: UIAlertController?
    
    private var displayMode: SettingsDiscoveryThreePidDetailsDisplayMode?

    // MARK: - Setup
    
    class func instantiate(with viewModel: SettingsDiscoveryThreePidDetailsViewModelType) -> SettingsDiscoveryThreePidDetailsViewController {
        let viewController = StoryboardScene.SettingsDiscoveryThreePidDetailsViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        vc_setLargeTitleDisplayMode(.never)
        self.setupViews()
        self.keyboardAvoider = KeyboardAvoider(scrollViewContainerView: self.view, scrollView: self.scrollView)
        self.activityPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = MXKErrorAlertPresentation()
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        self.viewModel.viewDelegate = self

        self.viewModel.process(viewAction: .load)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.keyboardAvoider?.startAvoiding()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.keyboardAvoider?.stopAvoiding()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        self.threePidBackgroundView.backgroundColor = theme.backgroundColor
        self.threePidTitleLabel.textColor = theme.textPrimaryColor
        self.threePidAdressLabel.textColor = theme.textSecondaryColor
        
        self.informationLabel.textColor = theme.textSecondaryColor
        self.operationButton.backgroundColor = theme.backgroundColor
        theme.applyStyle(onButton: self.operationButton)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        
        self.scrollView.keyboardDismissMode = .interactive
        
        self.render(threePid: self.viewModel.threePid)
    }
    
    private func render(threePid: MX3PID) {
        
        let title: String
        let threePidTitle: String
        let informationText: String
        let formattedThreePid: String
        
        switch threePid.medium {
        case .email:
            title = VectorL10n.settingsDiscoveryThreePidDetailsTitleEmail
            threePidTitle = VectorL10n.settingsEmailAddress
            informationText = VectorL10n.settingsDiscoveryThreePidDetailsInformationEmail
            formattedThreePid = threePid.address
        case .msisdn:
            title = VectorL10n.settingsDiscoveryThreePidDetailsTitlePhoneNumber
            threePidTitle = VectorL10n.settingsPhoneNumber
            informationText = VectorL10n.settingsDiscoveryThreePidDetailsInformationPhoneNumber
            formattedThreePid = MXKTools.readableMSISDN(threePid.address)
        default:
            title = ""
            threePidTitle = ""
            informationText = ""
            formattedThreePid = ""
        }
        
        self.title = title
        self.threePidTitleLabel.text = threePidTitle
        self.threePidAdressLabel.text = formattedThreePid
        self.informationLabel.text = informationText
    }
    
    private func render(viewState: SettingsDiscoveryThreePidDetailsViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .loaded(displayMode: let displayMode):
            self.renderLoaded(displayMode: displayMode)
        case .error(let error):
            self.render(error: error)
        }
    }
    
    private func renderLoaded(displayMode: SettingsDiscoveryThreePidDetailsDisplayMode) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        
        let operationButtonTitle: String?
        let operationButtonColor: UIColor?
        let operationButtonEnabled: Bool
        
        self.presentedAlertController?.dismiss(animated: false, completion: nil)
        
        switch displayMode {
        case .share:
            operationButtonTitle = VectorL10n.settingsDiscoveryThreePidDetailsShareAction
            operationButtonColor = self.theme.tintColor
            operationButtonEnabled = true
        case .revoke:
            operationButtonTitle = VectorL10n.settingsDiscoveryThreePidDetailsRevokeAction
            operationButtonColor = self.theme.warningColor
            operationButtonEnabled = true
        case .pendingThreePidVerification:
            switch self.viewModel.threePid.medium {
            case .email:
                self.presentPendingEmailVerificationAlert()
            case .msisdn:
                self.presentPendingMSISDNVerificationAlert()
            default:
                break
            }
            
            operationButtonTitle = nil
            operationButtonColor = nil
            operationButtonEnabled = false
        }
        
        if let operationButtonTitle = operationButtonTitle {
            self.operationButton.setTitle(operationButtonTitle, for: .normal)
        }
        
        if let operationButtonColor = operationButtonColor {
            self.operationButton.setTitleColor(operationButtonColor, for: .normal)
        }
        
        self.operationButton.isEnabled = operationButtonEnabled
        
        self.displayMode = displayMode
    }
    
    private func renderLoading() {
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
        self.operationButton.isEnabled = false
    }
    
    private func render(error: Error) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: {
            self.viewModel.process(viewAction: .cancelThreePidValidation)
        })
        self.operationButton.isEnabled = true
    }
    
    private func presentPendingEmailVerificationAlert() {
        
        let alert = UIAlertController(title: VectorL10n.accountEmailValidationTitle,
                                      message: VectorL10n.accountEmailValidationMessage,
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: VectorL10n.continue, style: .default, handler: { _ in
            self.viewModel.process(viewAction: .confirmEmailValidation)
        }))
        
        alert.addAction(UIAlertAction(title: VectorL10n.cancel, style: .cancel, handler: { _ in
            self.viewModel.process(viewAction: .cancelThreePidValidation)
        }))
        
        self.present(alert, animated: true, completion: nil)
        self.presentedAlertController = alert
    }
    
    private func presentPendingMSISDNVerificationAlert() {
        
        let alert = UIAlertController(title: VectorL10n.accountMsisdnValidationTitle,
                                      message: VectorL10n.accountMsisdnValidationMessage,
                                      preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = nil
            textField.keyboardType = .phonePad
        }
        
        alert.addAction(UIAlertAction(title: VectorL10n.continue, style: .default, handler: { _ in
            guard let textField =  alert.textFields?.first, let smsCode = textField.text, smsCode.isEmpty == false else {
                return
            }
            self.viewModel.process(viewAction: .confirmMSISDNValidation(code: smsCode))
        }))
        
        alert.addAction(UIAlertAction(title: VectorL10n.cancel, style: .cancel, handler: { _ in
            self.viewModel.process(viewAction: .cancelThreePidValidation)
        }))
        
        self.present(alert, animated: true, completion: nil)
        self.presentedAlertController = alert
    }
    
    // MARK: - Actions

    @IBAction private func operationButtonAction(_ sender: Any) {
        guard let displayMode = self.displayMode else {
            return
        }
        
        let viewAction: SettingsDiscoveryThreePidDetailsViewAction?
        
        switch displayMode {
        case .share:
            viewAction = .share
        case .revoke:
            viewAction = .revoke
        default:
            viewAction = nil
        }
        
        if let viewAction = viewAction {
            self.viewModel.process(viewAction: viewAction)
        }
    }
}

// MARK: - SettingsDiscoveryThreePidDetailsViewModelViewDelegate
extension SettingsDiscoveryThreePidDetailsViewController: SettingsDiscoveryThreePidDetailsViewModelViewDelegate {

    func settingsDiscoveryThreePidDetailsViewModel(_ viewModel: SettingsDiscoveryThreePidDetailsViewModelType, didUpdateViewState viewSate: SettingsDiscoveryThreePidDetailsViewState) {
        self.render(viewState: viewSate)
    }        
}
