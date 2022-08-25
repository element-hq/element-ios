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

    @IBOutlet private var scrollView: UIScrollView!

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var informationLabel: UILabel!
    @IBOutlet private var waitingPartnerLabel: UILabel!
    @IBOutlet private var useLegacyVerificationLabel: UILabel!
    @IBOutlet private var verifyButtonBackgroundView: UIView!
    @IBOutlet private var verifyButton: UIButton!
    @IBOutlet private var useLegacyVerificationButton: UIButton!

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
        
        title = VectorL10n.keyVerificationOtherSessionTitle
        vc_removeBackTitle()
        
        setupViews()
        activityPresenter = ActivityIndicatorPresenter()
        errorPresenter = MXKErrorAlertPresentation()
        
        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
        
        viewModel.viewDelegate = self
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }

        titleLabel.textColor = theme.textPrimaryColor
        informationLabel.textColor = theme.textPrimaryColor
        waitingPartnerLabel.textColor = theme.textPrimaryColor
        useLegacyVerificationLabel.textColor = theme.textPrimaryColor

        verifyButtonBackgroundView.backgroundColor = theme.backgroundColor
        theme.applyStyle(onButton: verifyButton)

        theme.applyStyle(onButton: useLegacyVerificationButton)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
            self?.cancelButtonAction()
        }
        
        navigationItem.rightBarButtonItem = cancelBarButtonItem
        
        scrollView.keyboardDismissMode = .interactive

        titleLabel.text = VectorL10n.deviceVerificationStartTitle
        informationLabel.text = VectorL10n.deviceVerificationSecurityAdviceNumber
        waitingPartnerLabel.text = VectorL10n.deviceVerificationStartWaitPartner
        useLegacyVerificationLabel.text = VectorL10n.deviceVerificationStartUseLegacy

        waitingPartnerLabel.isHidden = true
        useLegacyVerificationLabel.isHidden = true

        verifyButton.setTitle(VectorL10n.deviceVerificationStartVerifyButton, for: .normal)
        useLegacyVerificationButton.setTitle(VectorL10n.deviceVerificationStartUseLegacyAction, for: .normal)
    }

    private func render(viewState: DeviceVerificationStartViewState) {
        switch viewState {
        case .loading:
            renderLoading()
        case .loaded:
            renderStarted()
        case .verifyUsingLegacy(let session, let deviceInfo):
            renderVerifyUsingLegacy(session: session, deviceInfo: deviceInfo)
        case .cancelled(let reason):
            renderCancelled(reason: reason)
        case .cancelledByMe(let reason):
            renderCancelledByMe(reason: reason)
        case .error(let error):
            render(error: error)
        }
    }
    
    private func renderLoading() {
        activityPresenter.presentActivityIndicator(on: view, animated: true)
    }
    
    private func renderStarted() {
        activityPresenter.removeCurrentActivityIndicator(animated: true)

        verifyButtonBackgroundView.isHidden = true
        waitingPartnerLabel.isHidden = false
        useLegacyVerificationLabel.isHidden = false
    }

    private func renderVerifyUsingLegacy(session: MXSession, deviceInfo: MXDeviceInfo) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)

        guard let encryptionInfoView = EncryptionInfoView(deviceInfo: deviceInfo, andMatrixSession: session) else {
            return
        }

        encryptionInfoView.delegate = self

        // Skip the intro page
        encryptionInfoView.displayLegacyVerificationScreen()

        // Display the legacy verification view in full screen
        // TODO: Do not reuse the legacy EncryptionInfoView and create a screen from scratch
        view.vc_addSubViewMatchingParent(encryptionInfoView)
        navigationController?.isNavigationBarHidden = true
    }

    private func renderCancelled(reason: MXTransactionCancelCode) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)

        errorPresenter.presentError(from: self, title: "", message: VectorL10n.deviceVerificationCancelled, animated: true) {
            self.viewModel.process(viewAction: .cancel)
        }
    }

    private func renderCancelledByMe(reason: MXTransactionCancelCode) {
        if reason.value != MXTransactionCancelCode.user().value {
            activityPresenter.removeCurrentActivityIndicator(animated: true)

            errorPresenter.presentError(from: self, title: "", message: VectorL10n.deviceVerificationCancelledByMe(reason.humanReadable), animated: true) {
                self.viewModel.process(viewAction: .cancel)
            }
        } else {
            activityPresenter.removeCurrentActivityIndicator(animated: true)
        }
    }
    
    private func render(error: Error) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }

    // MARK: - Actions

    @IBAction private func verifyButtonAction(_ sender: Any) {
        viewModel.process(viewAction: .beginVerifying)
    }

    @IBAction private func useLegacyVerificationButtonAction(_ sender: Any) {
        viewModel.process(viewAction: .verifyUsingLegacy)
    }

    private func cancelButtonAction() {
        viewModel.process(viewAction: .cancel)
    }
}

// MARK: - DeviceVerificationStartViewModelViewDelegate

extension DeviceVerificationStartViewController: DeviceVerificationStartViewModelViewDelegate {
    func deviceVerificationStartViewModel(_ viewModel: DeviceVerificationStartViewModelType, didUpdateViewState viewSate: DeviceVerificationStartViewState) {
        render(viewState: viewSate)
    }
}

// MARK: - DeviceVerificationStartViewModelViewDelegate

extension DeviceVerificationStartViewController: MXKEncryptionInfoViewDelegate {
    func encryptionInfoView(_ encryptionInfoView: MXKEncryptionInfoView!, didDeviceInfoVerifiedChange deviceInfo: MXDeviceInfo!) {
        viewModel.process(viewAction: .verifiedUsingLegacy)
    }

    func encryptionInfoViewDidClose(_ encryptionInfoView: MXKEncryptionInfoView!) {
        viewModel.process(viewAction: .cancel)
    }
}
