// File created from ScreenTemplate
// $ createScreen.sh KeyVerification KeyVerificationSelfVerifyWait
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

final class KeyVerificationSelfVerifyWaitViewController: UIViewController {
    // MARK: - Constants
    
    private enum Constants {
        static let clientNamesLineSpacing: CGFloat = 3.0
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private var informationLabel: UILabel!
    
    @IBOutlet private var desktopClientImageView: UIImageView!
    @IBOutlet private var mobileClientImageView: UIImageView!
    
    @IBOutlet private var additionalInformationLabel: UILabel!
    
    @IBOutlet private var recoverSecretsAvailabilityLoadingContainerView: UIView!
    @IBOutlet private var recoverSecretsAvailabilityLoadingLabel: UILabel!
    @IBOutlet private var recoverSecretsAvailabilityActivityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private var recoverSecretsContainerView: UIView!
    @IBOutlet private var recoverSecretsButton: RoundedButton!
    @IBOutlet private var recoverSecretsAdditionalInformationLabel: UILabel!
    
    // MARK: Private

    private var viewModel: KeyVerificationSelfVerifyWaitViewModelType!
    private var cancellable: Bool!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    
    private weak var cancelBarButtonItem: UIBarButtonItem?

    // MARK: - Setup
    
    class func instantiate(with viewModel: KeyVerificationSelfVerifyWaitViewModelType, cancellable: Bool) -> KeyVerificationSelfVerifyWaitViewController {
        let viewController = StoryboardScene.KeyVerificationSelfVerifyWaitViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.cancellable = cancellable
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        setupViews()
        activityPresenter = ActivityIndicatorPresenter()
        errorPresenter = MXKErrorAlertPresentation()
        
        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
        
        viewModel.viewDelegate = self
        viewModel.process(viewAction: .loadData)
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
        
        informationLabel.textColor = theme.textPrimaryColor
        desktopClientImageView.tintColor = theme.tintColor
        mobileClientImageView.tintColor = theme.tintColor
        additionalInformationLabel.textColor = theme.textPrimaryColor
        recoverSecretsAvailabilityLoadingLabel.textColor = theme.textSecondaryColor
        recoverSecretsAvailabilityActivityIndicatorView.color = theme.tintColor
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        if cancellable {
            let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.skip, style: .plain) { [weak self] in
                self?.cancelButtonAction()
            }

            vc_removeBackTitle()

            navigationItem.rightBarButtonItem = cancelBarButtonItem
            self.cancelBarButtonItem = cancelBarButtonItem
        }
        
        title = VectorL10n.deviceVerificationSelfVerifyWaitTitle
        
        informationLabel.text = VectorL10n.deviceVerificationSelfVerifyWaitInformation(AppInfo.current.displayName)
        
        desktopClientImageView.image = Asset.Images.monitor.image.withRenderingMode(.alwaysTemplate)
        mobileClientImageView.image = Asset.Images.smartphone.image.withRenderingMode(.alwaysTemplate)
        
        additionalInformationLabel.text = VectorL10n.deviceVerificationSelfVerifyWaitAdditionalInformation(AppInfo.current.displayName)
        
        recoverSecretsAdditionalInformationLabel.text = VectorL10n.deviceVerificationSelfVerifyWaitRecoverSecretsAdditionalInformation
    }

    private func render(viewState: KeyVerificationSelfVerifyWaitViewState) {
        switch viewState {
        case .loading:
            renderLoading()
        case .secretsRecoveryCheckingAvailability(let text):
            renderSecretsRecoveryCheckingAvailability(withText: text)
        case .loaded(let viewData):
            renderLoaded(viewData: viewData)
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
    
    private func renderSecretsRecoveryCheckingAvailability(withText text: String?) {
        recoverSecretsAvailabilityLoadingLabel.text = text
        recoverSecretsAvailabilityActivityIndicatorView.startAnimating()
        recoverSecretsAvailabilityLoadingContainerView.isHidden = false
        recoverSecretsContainerView.isHidden = true
    }
    
    private func renderLoaded(viewData: KeyVerificationSelfVerifyWaitViewData) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        
        title = viewData.isNewSignIn ? VectorL10n.deviceVerificationSelfVerifyWaitNewSignInTitle : VectorL10n.deviceVerificationSelfVerifyWaitTitle
        cancelBarButtonItem?.title = viewData.isNewSignIn ? VectorL10n.skip : VectorL10n.cancel
   
        let hideRecoverSecrets: Bool
        let recoverSecretsButtonTitle: String?
        
        switch viewData.secretsRecoveryAvailability {
        case .notAvailable:
            hideRecoverSecrets = true
            recoverSecretsButtonTitle = nil
        case .available(let secretsRecoveryMode):
            hideRecoverSecrets = false
            
            switch secretsRecoveryMode {
            case .passphraseOrKey:
                recoverSecretsButtonTitle = VectorL10n.deviceVerificationSelfVerifyWaitRecoverSecretsWithPassphrase
            case .onlyKey:
                recoverSecretsButtonTitle = VectorL10n.deviceVerificationSelfVerifyWaitRecoverSecretsWithoutPassphrase
            }
        }
        
        recoverSecretsAvailabilityLoadingContainerView.isHidden = true
        recoverSecretsAvailabilityActivityIndicatorView.stopAnimating()
        recoverSecretsContainerView.isHidden = hideRecoverSecrets
        recoverSecretsButton.setTitle(recoverSecretsButtonTitle, for: .normal)
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
    
    private func cancelButtonAction() {
        viewModel.process(viewAction: .cancel)
    }
    
    @IBAction private func recoverSecretsButtonAction(_ sender: Any) {
        viewModel.process(viewAction: .recoverSecrets)
    }
}

// MARK: - KeyVerificationSelfVerifyWaitViewModelViewDelegate

extension KeyVerificationSelfVerifyWaitViewController: KeyVerificationSelfVerifyWaitViewModelViewDelegate {
    func keyVerificationSelfVerifyWaitViewModel(_ viewModel: KeyVerificationSelfVerifyWaitViewModelType, didUpdateViewState viewSate: KeyVerificationSelfVerifyWaitViewState) {
        render(viewState: viewSate)
    }
}
