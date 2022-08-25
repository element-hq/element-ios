// File created from ScreenTemplate
// $ createScreen.sh Test SettingsIdentityServer
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

final class SettingsIdentityServerViewController: UIViewController {
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private var scrollView: UIScrollView!
    
    @IBOutlet var identityServerContainer: UIView!
    @IBOutlet var identityServerLabel: UILabel!
    @IBOutlet var identityServerTextField: UITextField!

    @IBOutlet private var messageLabel: UILabel!

    @IBOutlet var addOrChangeButtonContainer: UIView!
    @IBOutlet private var addOrChangeButton: UIButton!
    
    @IBOutlet var disconnectMessageLabel: UILabel!
    @IBOutlet var disconnectButtonContainer: UIView!
    @IBOutlet var disconnectButton: UIButton!

    // MARK: Private

    private var viewModel: SettingsIdentityServerViewModelType!
    private var theme: Theme!
    private var keyboardAvoider: KeyboardAvoider?
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    private var viewState: SettingsIdentityServerViewState?
    
    private var displayMode: SettingsIdentityServerDisplayMode?

    private weak var alertController: UIAlertController?

    private var serviceTermsModalCoordinatorBridgePresenter: ServiceTermsModalCoordinatorBridgePresenter?
    private var serviceTermsModalCoordinatorBridgePresenterOnComplete: ((Bool) -> Void)?

    // MARK: - Setup
    
    class func instantiate(with viewModel: SettingsIdentityServerViewModelType) -> SettingsIdentityServerViewController {
        let viewController = StoryboardScene.SettingsIdentityServerViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        title = VectorL10n.identityServerSettingsTitle
        
        setupViews()
        keyboardAvoider = KeyboardAvoider(scrollViewContainerView: view, scrollView: scrollView)
        activityPresenter = ActivityIndicatorPresenter()
        errorPresenter = MXKErrorAlertPresentation()
        
        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
        
        viewModel.viewDelegate = self

        viewModel.process(viewAction: .load)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        keyboardAvoider?.startAvoiding()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        keyboardAvoider?.stopAvoiding()
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

        identityServerContainer.backgroundColor = theme.backgroundColor
        identityServerLabel.textColor = theme.textPrimaryColor
        theme.applyStyle(onTextField: identityServerTextField)
        identityServerTextField.textColor = theme.textSecondaryColor
        messageLabel.textColor = theme.textPrimaryColor

        addOrChangeButtonContainer.backgroundColor = theme.backgroundColor
        theme.applyStyle(onButton: addOrChangeButton)

        disconnectMessageLabel.textColor = theme.textPrimaryColor
        disconnectButtonContainer.backgroundColor = theme.backgroundColor
        theme.applyStyle(onButton: disconnectButton)
        disconnectButton.setTitleColor(self.theme.warningColor, for: .normal)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        scrollView.keyboardDismissMode = .interactive

        identityServerLabel.text = VectorL10n.identityServerSettingsTitle

        identityServerTextField.placeholder = VectorL10n.identityServerSettingsPlaceHolder
        identityServerTextField.addTarget(self, action: #selector(identityServerTextFieldDidChange(_:)), for: .editingChanged)
        identityServerTextField.addTarget(self, action: #selector(identityServerTextFieldDidEndOnExit(_:)), for: .editingDidEndOnExit)

        disconnectMessageLabel.text = VectorL10n.identityServerSettingsDisconnectInfo
        disconnectButton.setTitle(VectorL10n.identityServerSettingsDisconnect, for: .normal)
        disconnectButton.setTitle(VectorL10n.identityServerSettingsDisconnect, for: .highlighted)
    }

    private func render(viewState: SettingsIdentityServerViewState) {
        switch viewState {
        case .loading:
            renderLoading()
        case .loaded(let displayMode):
            renderLoaded(displayMode: displayMode)
        case .presentTerms(let session, let accessToken, let baseUrl, let onComplete):
            presentTerms(session: session, accessToken: accessToken, baseUrl: baseUrl, onComplete: onComplete)
        case .alert(let alert, let onContinue):
            renderAlert(alert: alert, onContinue: onContinue)
        case .error(let error):
            render(error: error)
        }
    }
    
    private func renderLoading() {
        activityPresenter.presentActivityIndicator(on: view, animated: true)
    }
    
    private func renderLoaded(displayMode: SettingsIdentityServerDisplayMode) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)

        self.displayMode = displayMode

        switch displayMode {
        case .noIdentityServer:
            renderNoIdentityServer()
        case .identityServer(let host):
            renderIdentityServer(host: host)
        }
    }

    private func renderNoIdentityServer() {
        activityPresenter.removeCurrentActivityIndicator(animated: true)

        identityServerTextField.text = nil
        messageLabel.text = VectorL10n.identityServerSettingsNoIsDescription

        addOrChangeButton.setTitle(VectorL10n.identityServerSettingsAdd, for: .normal)
        addOrChangeButton.setTitle(VectorL10n.identityServerSettingsAdd, for: .highlighted)
        addOrChangeButton.isEnabled = false

        disconnectMessageLabel.isHidden = true
        disconnectButtonContainer.isHidden = true
    }

    private func renderIdentityServer(host: String) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)

        identityServerTextField.text = host
        messageLabel.text = VectorL10n.identityServerSettingsDescription(host.hostname())

        addOrChangeButton.setTitle(VectorL10n.identityServerSettingsChange, for: .normal)
        addOrChangeButton.setTitle(VectorL10n.identityServerSettingsChange, for: .highlighted)
        addOrChangeButton.isEnabled = false

        disconnectMessageLabel.isHidden = false
        disconnectButtonContainer.isHidden = false
    }

    private func presentTerms(session: MXSession, accessToken: String, baseUrl: String, onComplete: @escaping (Bool) -> Void) {
        let serviceTermsModalCoordinatorBridgePresenter = ServiceTermsModalCoordinatorBridgePresenter(session: session, baseUrl: baseUrl, serviceType: MXServiceTypeIdentityService, accessToken: accessToken)

        serviceTermsModalCoordinatorBridgePresenter.present(from: self, animated: true)
        serviceTermsModalCoordinatorBridgePresenter.delegate = self

        self.serviceTermsModalCoordinatorBridgePresenter = serviceTermsModalCoordinatorBridgePresenter
        serviceTermsModalCoordinatorBridgePresenterOnComplete = onComplete
    }

    private func hideTerms(accepted: Bool) {
        guard let serviceTermsModalCoordinatorBridgePresenterOnComplete = serviceTermsModalCoordinatorBridgePresenterOnComplete else {
            return
        }
        serviceTermsModalCoordinatorBridgePresenter?.dismiss(animated: true, completion: nil)
        serviceTermsModalCoordinatorBridgePresenter = nil

        serviceTermsModalCoordinatorBridgePresenterOnComplete(accepted)
        self.serviceTermsModalCoordinatorBridgePresenterOnComplete = nil
    }

    private func renderAlert(alert: SettingsIdentityServerAlert, onContinue: @escaping () -> Void) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        
        switch alert {
        case .addActionAlert(.invalidIdentityServer(let newHost)),
             .changeActionAlert(.invalidIdentityServer(let newHost)):
            showAlert(title: nil,
                      message: VectorL10n.identityServerSettingsAlertErrorInvalidIdentityServer(newHost),
                      continueButtonTitle: nil,
                      cancelButtonTitle: VectorL10n.cancel,
                      onContinue: onContinue)

        case .addActionAlert(.noTerms),
             .changeActionAlert(.noTerms):
            showAlert(title: VectorL10n.identityServerSettingsAlertNoTermsTitle,
                      message: VectorL10n.identityServerSettingsAlertNoTerms,
                      continueButtonTitle: VectorL10n.continue,
                      cancelButtonTitle: VectorL10n.cancel,
                      onContinue: onContinue)

        case .addActionAlert(.termsNotAccepted(let newHost)),
             .changeActionAlert(.termsNotAccepted(let newHost)):
            showAlert(title: nil,
                      message: VectorL10n.identityServerSettingsAlertErrorTermsNotAccepted(newHost.hostname()),
                      continueButtonTitle: nil,
                      cancelButtonTitle: VectorL10n.cancel,
                      onContinue: onContinue)

        case .changeActionAlert(.stillSharing3Pids(let oldHost, _)):
            showAlert(title: VectorL10n.identityServerSettingsAlertChangeTitle,
                      message: VectorL10n.identityServerSettingsAlertDisconnectStillSharing3pid(oldHost.hostname()),
                      continueButtonTitle: VectorL10n.identityServerSettingsAlertDisconnectStillSharing3pidButton,
                      cancelButtonTitle: VectorL10n.cancel,
                      onContinue: onContinue)

        case .changeActionAlert(.doubleConfirmation(let oldHost, let newHost)):
            showAlert(title: VectorL10n.identityServerSettingsAlertChangeTitle,
                      message: VectorL10n.identityServerSettingsAlertChange(oldHost.hostname(), newHost.hostname()),
                      continueButtonTitle: VectorL10n.continue,
                      cancelButtonTitle: VectorL10n.cancel,
                      onContinue: onContinue)

        case .disconnectActionAlert(.stillSharing3Pids(let oldHost)):
            showAlert(title: VectorL10n.identityServerSettingsAlertDisconnectTitle,
                      message: VectorL10n.identityServerSettingsAlertDisconnectStillSharing3pid(oldHost.hostname()),
                      continueButtonTitle: VectorL10n.identityServerSettingsAlertDisconnectStillSharing3pidButton,
                      cancelButtonTitle: VectorL10n.cancel,
                      onContinue: onContinue)

        case .disconnectActionAlert(.doubleConfirmation(let oldHost)):
            showAlert(title: VectorL10n.identityServerSettingsAlertDisconnectTitle,
                      message: VectorL10n.identityServerSettingsAlertDisconnect(oldHost.hostname()),
                      continueButtonTitle: VectorL10n.identityServerSettingsAlertDisconnectButton,
                      cancelButtonTitle: VectorL10n.cancel,
                      onContinue: onContinue)
        }
    }

    private func render(error: Error) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }

    // MARK: - Alert

    private func showAlert(title: String?, message: String, continueButtonTitle: String?, cancelButtonTitle: String, onContinue: @escaping () -> Void) {
        guard self.alertController == nil else {
            return
        }

        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: cancelButtonTitle, style: .cancel, handler: { _ in
        }))

        if let continueButtonTitle = continueButtonTitle {
            alertController.addAction(UIAlertAction(title: continueButtonTitle, style: .default, handler: { _ in
                onContinue()
            }))
        }

        present(alertController, animated: true, completion: nil)
        self.alertController = alertController
    }

    private func hideAlert(animated: Bool) {
        alertController?.dismiss(animated: true, completion: nil)
    }

    // MARK: - Actions

    @objc private func identityServerTextFieldDidChange(_ textField: UITextField) {
        addOrChangeButton.isEnabled = textField.text?.count ?? 0 > 0
            && (textField.text?.hostname() != viewModel.identityServer?.hostname())
    }

    @objc private func identityServerTextFieldDidEndOnExit(_ textField: UITextField) {
        addOrChangeAction()
    }

    @IBAction private func addOrChangeButtonAction(_ sender: Any) {
        addOrChangeAction()
    }

    private func addOrChangeAction() {
        identityServerTextField.resignFirstResponder()

        guard
            let displayMode = displayMode,
            let identityServer = identityServerTextField.text?.trimmingCharacters(in: .whitespaces),
            !identityServer.isEmpty
        else {
            viewModel.process(viewAction: .load)
            return
        }
        
        let viewAction: SettingsIdentityServerViewAction?
        
        switch displayMode {
        case .noIdentityServer:
            viewAction = .add(identityServer: identityServer.makeURLValid())
        case .identityServer:
            viewAction = .change(identityServer: identityServer.makeURLValid())
        }
        
        if let viewAction = viewAction {
            viewModel.process(viewAction: viewAction)
        }
    }

    @IBAction private func disconnectButtonAction(_ sender: Any) {
        viewModel.process(viewAction: .disconnect)
    }
}

// MARK: - SettingsIdentityServerViewModelViewDelegate

extension SettingsIdentityServerViewController: SettingsIdentityServerViewModelViewDelegate {
    func settingsIdentityServerViewModel(_ viewModel: SettingsIdentityServerViewModelType, didUpdateViewState viewState: SettingsIdentityServerViewState) {
        self.viewState = viewState
        render(viewState: viewState)
    }
}

// MARK: - ServiceTermsModalCoordinatorBridgePresenterDelegate

extension SettingsIdentityServerViewController: ServiceTermsModalCoordinatorBridgePresenterDelegate {
    func serviceTermsModalCoordinatorBridgePresenterDelegateDidAccept(_ coordinatorBridgePresenter: ServiceTermsModalCoordinatorBridgePresenter) {
        hideTerms(accepted: true)
    }

    func serviceTermsModalCoordinatorBridgePresenterDelegateDidDecline(_ coordinatorBridgePresenter: ServiceTermsModalCoordinatorBridgePresenter, session: MXSession) {
        hideTerms(accepted: false)
    }

    func serviceTermsModalCoordinatorBridgePresenterDelegateDidClose(_ coordinatorBridgePresenter: ServiceTermsModalCoordinatorBridgePresenter) {
        hideTerms(accepted: false)
    }
}

// MARK: - Private extension

private extension String {
    func hostname() -> String {
        URL(string: self)?.host ?? self
    }

    func makeURLValid() -> String {
        if hasPrefix("http://") || hasPrefix("https://") {
            return self
        } else {
            return "https://" + self
        }
    }
}
