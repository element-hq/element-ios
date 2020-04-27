// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Start DeviceVerificationStart
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

final class DeviceVerificationStartViewController: UIViewController {
    
    // MARK: - Constants
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private weak var scrollView: UIScrollView!

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var informationLabel: UILabel!
    @IBOutlet private weak var waitingPartnerLabel: UILabel!
    @IBOutlet private weak var useLegacyVerificationLabel: UILabel!
    @IBOutlet private weak var verifyButtonBackgroundView: UIView!
    @IBOutlet private weak var verifyButton: UIButton!
    @IBOutlet private weak var useLegacyVerificationButton: UIButton!

    // MARK: Private

    private var viewModel: DeviceVerificationStartViewModelType!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!

    // MARK: - Setup
    
    class func instantiate(with viewModel: DeviceVerificationStartViewModelType) -> DeviceVerificationStartViewController {
        let viewController = StoryboardScene.DeviceVerificationStartViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.title = VectorL10n.keyVerificationOtherSessionTitle
        self.vc_removeBackTitle()
        
        self.setupViews()
        self.activityPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = MXKErrorAlertPresentation()
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        self.viewModel.viewDelegate = self
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

        self.titleLabel.textColor = theme.textPrimaryColor
        self.informationLabel.textColor = theme.textPrimaryColor
        self.waitingPartnerLabel.textColor = theme.textPrimaryColor
        self.useLegacyVerificationLabel.textColor = theme.textPrimaryColor

        self.verifyButtonBackgroundView.backgroundColor = theme.backgroundColor
        theme.applyStyle(onButton: self.verifyButton)

        theme.applyStyle(onButton: self.useLegacyVerificationButton)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
            self?.cancelButtonAction()
        }
        
        self.navigationItem.rightBarButtonItem = cancelBarButtonItem
        
        self.scrollView.keyboardDismissMode = .interactive

        self.titleLabel.text = VectorL10n.deviceVerificationStartTitle
        self.informationLabel.text = VectorL10n.deviceVerificationSecurityAdviceNumber
        self.waitingPartnerLabel.text = VectorL10n.deviceVerificationStartWaitPartner
        self.useLegacyVerificationLabel.text = VectorL10n.deviceVerificationStartUseLegacy

        self.waitingPartnerLabel.isHidden = true
        self.useLegacyVerificationLabel.isHidden = true

        self.verifyButton.setTitle(VectorL10n.deviceVerificationStartVerifyButton, for: .normal)
        self.useLegacyVerificationButton.setTitle(VectorL10n.deviceVerificationStartUseLegacyAction, for: .normal)
    }

    private func render(viewState: DeviceVerificationStartViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .loaded:
            self.renderStarted()
        case .verifyUsingLegacy(let session, let deviceInfo):
            self.renderVerifyUsingLegacy(session: session, deviceInfo: deviceInfo)
        case .cancelled(let reason):
            self.renderCancelled(reason: reason)
        case .cancelledByMe(let reason):
            self.renderCancelledByMe(reason: reason)
        case .error(let error):
            self.render(error: error)
        }
    }
    
    private func renderLoading() {
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
    }
    
    private func renderStarted() {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)

        self.verifyButtonBackgroundView.isHidden = true
        self.waitingPartnerLabel.isHidden = false
        self.useLegacyVerificationLabel.isHidden = false
    }

    private func renderVerifyUsingLegacy(session: MXSession, deviceInfo: MXDeviceInfo) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)

        guard let encryptionInfoView = EncryptionInfoView(deviceInfo: deviceInfo, andMatrixSession: session) else {
            return
        }

        encryptionInfoView.delegate = self

        // Skip the intro page
        encryptionInfoView.displayLegacyVerificationScreen()

        // Display the legacy verification view in full screen
        // TODO: Do not reuse the legacy EncryptionInfoView and create a screen from scratch
        self.view.vc_addSubViewMatchingParent(encryptionInfoView)
        self.navigationController?.isNavigationBarHidden = true
    }

    private func renderCancelled(reason: MXTransactionCancelCode) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)

        self.errorPresenter.presentError(from: self, title: "", message: VectorL10n.deviceVerificationCancelled, animated: true) {
            self.viewModel.process(viewAction: .cancel)
        }
    }

    private func renderCancelledByMe(reason: MXTransactionCancelCode) {
        if reason.value != MXTransactionCancelCode.user().value {
            self.activityPresenter.removeCurrentActivityIndicator(animated: true)

            self.errorPresenter.presentError(from: self, title: "", message: VectorL10n.deviceVerificationCancelledByMe(reason.humanReadable), animated: true) {
                self.viewModel.process(viewAction: .cancel)
            }
        } else {
            self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        }
    }
    
    private func render(error: Error) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }

    
    // MARK: - Actions

    @IBAction private func verifyButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .beginVerifying)
    }

    @IBAction private func useLegacyVerificationButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .verifyUsingLegacy)
    }

    private func cancelButtonAction() {
        self.viewModel.process(viewAction: .cancel)
    }
}


// MARK: - DeviceVerificationStartViewModelViewDelegate
extension DeviceVerificationStartViewController: DeviceVerificationStartViewModelViewDelegate {

    func deviceVerificationStartViewModel(_ viewModel: DeviceVerificationStartViewModelType, didUpdateViewState viewSate: DeviceVerificationStartViewState) {
        self.render(viewState: viewSate)
    }
}

// MARK: - DeviceVerificationStartViewModelViewDelegate
extension DeviceVerificationStartViewController: MXKEncryptionInfoViewDelegate {
    func encryptionInfoView(_ encryptionInfoView: MXKEncryptionInfoView!, didDeviceInfoVerifiedChange deviceInfo: MXDeviceInfo!) {
        self.viewModel.process(viewAction: .verifiedUsingLegacy)
    }

    func encryptionInfoViewDidClose(_ encryptionInfoView: MXKEncryptionInfoView!) {
        self.viewModel.process(viewAction: .cancel)
    }
}
