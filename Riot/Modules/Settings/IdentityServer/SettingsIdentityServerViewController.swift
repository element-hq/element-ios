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

    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet weak var identityServerContainer: UIView!
    @IBOutlet weak var identityServerLabel: UILabel!
    @IBOutlet weak var identityServerTextField: UITextField!

    @IBOutlet private weak var messageLabel: UILabel!

    @IBOutlet weak var addOrChangeButtonContainer: UIView!
    @IBOutlet private weak var addOrChangeButton: UIButton!
    
    @IBOutlet weak var disconnectMessageLabel: UILabel!
    @IBOutlet weak var disconnectButtonContainer: UIView!
    @IBOutlet weak var disconnectButton: UIButton!

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
        
        self.title = VectorL10n.identityServerSettingsTitle
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

        self.identityServerContainer.backgroundColor = theme.backgroundColor
        self.identityServerLabel.textColor = theme.textPrimaryColor
        theme.applyStyle(onTextField: self.identityServerTextField)
        self.identityServerTextField.textColor = theme.textSecondaryColor
        self.messageLabel.textColor = theme.textPrimaryColor

        self.addOrChangeButtonContainer.backgroundColor = theme.backgroundColor
        theme.applyStyle(onButton: self.addOrChangeButton)

        self.disconnectMessageLabel.textColor = theme.textPrimaryColor
        self.disconnectButtonContainer.backgroundColor = theme.backgroundColor
        theme.applyStyle(onButton: self.disconnectButton)
        self.disconnectButton.setTitleColor(self.theme.warningColor, for: .normal)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        self.scrollView.keyboardDismissMode = .interactive

        self.identityServerLabel.text = VectorL10n.identityServerSettingsTitle

        self.identityServerTextField.placeholder = VectorL10n.identityServerSettingsPlaceHolder
        self.identityServerTextField.addTarget(self, action: #selector(identityServerTextFieldDidChange(_:)), for: .editingChanged)
        self.identityServerTextField.addTarget(self, action: #selector(identityServerTextFieldDidEndOnExit(_:)), for: .editingDidEndOnExit)

        self.disconnectMessageLabel.text = VectorL10n.identityServerSettingsDisconnectInfo
        self.disconnectButton.setTitle(VectorL10n.identityServerSettingsDisconnect, for: .normal)
        self.disconnectButton.setTitle(VectorL10n.identityServerSettingsDisconnect, for: .highlighted)
    }

    private func render(viewState: SettingsIdentityServerViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .loaded(let displayMode):
            self.renderLoaded(displayMode: displayMode)
        case .presentTerms(let session, let accessToken, let baseUrl, let onComplete):
            self.presentTerms(session: session, accessToken: accessToken, baseUrl: baseUrl, onComplete: onComplete)
        case .alert(let alert, let onContinue):
            self.renderAlert(alert: alert, onContinue: onContinue)
        case .error(let error):
            self.render(error: error)
        }
    }
    
    private func renderLoading() {
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
    }
    
    private func renderLoaded(displayMode: SettingsIdentityServerDisplayMode) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)

        self.displayMode = displayMode

        switch displayMode {
        case .noIdentityServer:
            self.renderNoIdentityServer()
        case .identityServer(let host):
            self.renderIdentityServer(host: host)
        }
    }

    private func renderNoIdentityServer() {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)

        self.identityServerTextField.text = nil
        self.messageLabel.text = VectorL10n.identityServerSettingsNoIsDescription

        self.addOrChangeButton.setTitle(VectorL10n.identityServerSettingsAdd, for: .normal)
        self.addOrChangeButton.setTitle(VectorL10n.identityServerSettingsAdd, for: .highlighted)
        self.addOrChangeButton.isEnabled = false

        self.disconnectMessageLabel.isHidden = true
        self.disconnectButtonContainer.isHidden = true
    }

    private func renderIdentityServer(host: String) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)

        self.identityServerTextField.text = host
        self.messageLabel.text = VectorL10n.identityServerSettingsDescription(host.hostname())

        self.addOrChangeButton.setTitle(VectorL10n.identityServerSettingsChange, for: .normal)
        self.addOrChangeButton.setTitle(VectorL10n.identityServerSettingsChange, for: .highlighted)
        self.addOrChangeButton.isEnabled = false

        self.disconnectMessageLabel.isHidden = false
        self.disconnectButtonContainer.isHidden = false
    }

    private func presentTerms(session: MXSession, accessToken: String, baseUrl: String, onComplete: @escaping (Bool) -> Void) {
        let serviceTermsModalCoordinatorBridgePresenter = ServiceTermsModalCoordinatorBridgePresenter(session: session, baseUrl: baseUrl, serviceType: MXServiceTypeIdentityService, accessToken: accessToken)

        serviceTermsModalCoordinatorBridgePresenter.present(from: self, animated: true)
        serviceTermsModalCoordinatorBridgePresenter.delegate = self

        self.serviceTermsModalCoordinatorBridgePresenter = serviceTermsModalCoordinatorBridgePresenter
        self.serviceTermsModalCoordinatorBridgePresenterOnComplete = onComplete
    }

    private func hideTerms(accepted: Bool) {
        guard let serviceTermsModalCoordinatorBridgePresenterOnComplete = self.serviceTermsModalCoordinatorBridgePresenterOnComplete else {
            return
        }
        self.serviceTermsModalCoordinatorBridgePresenter?.dismiss(animated: true, completion: nil)
        self.serviceTermsModalCoordinatorBridgePresenter = nil

        serviceTermsModalCoordinatorBridgePresenterOnComplete(accepted)
        self.serviceTermsModalCoordinatorBridgePresenterOnComplete = nil
    }

    private func renderAlert(alert: SettingsIdentityServerAlert, onContinue: @escaping () -> Void) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        
        switch alert {
        case .addActionAlert(.invalidIdentityServer(let newHost)),
             .changeActionAlert(.invalidIdentityServer(let newHost)):
            self.showAlert(title: nil,
                           message: VectorL10n.identityServerSettingsAlertErrorInvalidIdentityServer(newHost),
                           continueButtonTitle: nil,
                           cancelButtonTitle: VectorL10n.cancel,
                           onContinue: onContinue)

        case .addActionAlert(.noTerms),
             .changeActionAlert(.noTerms):
            self.showAlert(title: VectorL10n.identityServerSettingsAlertNoTermsTitle,
                           message: VectorL10n.identityServerSettingsAlertNoTerms,
                           continueButtonTitle: VectorL10n.continue,
                           cancelButtonTitle: VectorL10n.cancel,
                           onContinue: onContinue)

        case .addActionAlert(.termsNotAccepted(let newHost)),
             .changeActionAlert(.termsNotAccepted(let newHost)):
            self.showAlert(title: nil,
                           message: VectorL10n.identityServerSettingsAlertErrorTermsNotAccepted(newHost.hostname()),
                           continueButtonTitle: nil,
                           cancelButtonTitle: VectorL10n.cancel,
                           onContinue: onContinue)


        case .changeActionAlert(.stillSharing3Pids(let oldHost, _)):
            self.showAlert(title: VectorL10n.identityServerSettingsAlertChangeTitle,
                           message: VectorL10n.identityServerSettingsAlertDisconnectStillSharing3pid(oldHost.hostname()),
                           continueButtonTitle: VectorL10n.identityServerSettingsAlertDisconnectStillSharing3pidButton,
                           cancelButtonTitle: VectorL10n.cancel,
                           onContinue: onContinue)

        case .changeActionAlert(.doubleConfirmation(let oldHost, let newHost)):
            self.showAlert(title: VectorL10n.identityServerSettingsAlertChangeTitle,
                           message: VectorL10n.identityServerSettingsAlertChange(oldHost.hostname(), newHost.hostname()),
                           continueButtonTitle: VectorL10n.continue,
                           cancelButtonTitle: VectorL10n.cancel,
                           onContinue: onContinue)


        case .disconnectActionAlert(.stillSharing3Pids(let oldHost)):
            self.showAlert(title: VectorL10n.identityServerSettingsAlertDisconnectTitle,
                           message: VectorL10n.identityServerSettingsAlertDisconnectStillSharing3pid(oldHost.hostname()),
                           continueButtonTitle: VectorL10n.identityServerSettingsAlertDisconnectStillSharing3pidButton,
                           cancelButtonTitle: VectorL10n.cancel,
                           onContinue: onContinue)

        case .disconnectActionAlert(.doubleConfirmation(let oldHost)):
            self.showAlert(title: VectorL10n.identityServerSettingsAlertDisconnectTitle,
                           message: VectorL10n.identityServerSettingsAlertDisconnect(oldHost.hostname()),
                           continueButtonTitle: VectorL10n.identityServerSettingsAlertDisconnectButton,
                           cancelButtonTitle: VectorL10n.cancel,
                           onContinue: onContinue)
        }
    }

    private func render(error: Error) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }


    // MARK: - Alert

    private func showAlert(title: String?, message: String, continueButtonTitle: String?, cancelButtonTitle: String, onContinue: @escaping () -> Void) {
        guard self.alertController == nil else {
            return
        }

        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: cancelButtonTitle, style: .cancel, handler: { action in
        }))

        if let continueButtonTitle = continueButtonTitle {
            alertController.addAction(UIAlertAction(title: continueButtonTitle, style: .default, handler: { action in
                onContinue()
            }))
        }

        self.present(alertController, animated: true, completion: nil)
        self.alertController = alertController
    }

    private func hideAlert(animated: Bool) {
        self.alertController?.dismiss(animated: true, completion: nil)
    }


    // MARK: - Actions

    @objc private func identityServerTextFieldDidChange(_ textField: UITextField) {
        self.addOrChangeButton.isEnabled = textField.text?.count ?? 0 > 0
            && (textField.text?.hostname() != self.viewModel.identityServer?.hostname())
    }

    @objc private func identityServerTextFieldDidEndOnExit(_ textField: UITextField) {
        self.addOrChangeAction()
    }


    @IBAction private func addOrChangeButtonAction(_ sender: Any) {
        self.addOrChangeAction()
    }

    private func addOrChangeAction() {
        self.identityServerTextField.resignFirstResponder()

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
            self.viewModel.process(viewAction: viewAction)
        }
    }

    @IBAction private func disconnectButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .disconnect)
    }
    
}


// MARK: - SettingsIdentityServerViewModelViewDelegate
extension SettingsIdentityServerViewController: SettingsIdentityServerViewModelViewDelegate {

    func settingsIdentityServerViewModel(_ viewModel: SettingsIdentityServerViewModelType, didUpdateViewState viewState: SettingsIdentityServerViewState) {
        self.viewState = viewState
        self.render(viewState: viewState)
    }
}


// MARK: - ServiceTermsModalCoordinatorBridgePresenterDelegate
extension SettingsIdentityServerViewController: ServiceTermsModalCoordinatorBridgePresenterDelegate {
    func serviceTermsModalCoordinatorBridgePresenterDelegateDidAccept(_ coordinatorBridgePresenter: ServiceTermsModalCoordinatorBridgePresenter) {
        self.hideTerms(accepted: true)
    }

    func serviceTermsModalCoordinatorBridgePresenterDelegateDidDecline(_ coordinatorBridgePresenter: ServiceTermsModalCoordinatorBridgePresenter, session: MXSession) {
        self.hideTerms(accepted: false)
    }

    func serviceTermsModalCoordinatorBridgePresenterDelegateDidClose(_ coordinatorBridgePresenter: ServiceTermsModalCoordinatorBridgePresenter) {
         self.hideTerms(accepted: false)
    }
}


// MARK: - Private extension
fileprivate extension String {
    func hostname() -> String {
        return URL(string: self)?.host ?? self
    }

    func makeURLValid() -> String {
        if self.hasPrefix("http://") || self.hasPrefix("https://") {
            return self
        } else {
            return "https://" + self
        }
    }
}
