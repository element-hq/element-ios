// File created from ScreenTemplate
// $ createScreen.sh KeyVerification KeyVerificationSelfVerifyStart
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

final class KeyVerificationSelfVerifyStartViewController: UIViewController {
    
    // MARK: - Constants
    
    private enum Constants {
        static let verifyButtonCornerRadius: CGFloat = 8.0        
    }
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private weak var informationLabel: UILabel!
    
    @IBOutlet private weak var startVerificationButton: UIButton!
    @IBOutlet private weak var verificationWaitingLabel: UILabel!
    
    @IBOutlet private weak var additionalInformationLabel: UILabel!
    
    // MARK: Private

    private var viewModel: KeyVerificationSelfVerifyStartViewModelType!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!

    // MARK: - Setup
    
    class func instantiate(with viewModel: KeyVerificationSelfVerifyStartViewModelType) -> KeyVerificationSelfVerifyStartViewController {
        let viewController = StoryboardScene.KeyVerificationSelfVerifyStartViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.title = VectorL10n.keyVerificationNewSessionTitle
        
        self.setupViews()
        self.activityPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = MXKErrorAlertPresentation()
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        self.viewModel.viewDelegate = self

        self.viewModel.process(viewAction: .loadData)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navigationController = self.navigationController {
            if navigationController.navigationBar.isHidden == true {
                self.navigationItem.hidesBackButton = true
                // Show navigation bar if needed
                navigationController.setNavigationBarHidden(false, animated: animated)
            } else {
                // Hide back button
                self.navigationItem.setHidesBackButton(true, animated: animated)
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.startVerificationButton.layer.cornerRadius = Constants.verifyButtonCornerRadius
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
        
        self.informationLabel.textColor = theme.textPrimaryColor
        self.startVerificationButton.vc_setBackgroundColor(theme.tintColor, for: .normal)
        self.verificationWaitingLabel.textColor = theme.textSecondaryColor
        self.additionalInformationLabel.textColor = theme.textSecondaryColor
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
        
        self.startVerificationButton.layer.masksToBounds = true
        self.startVerificationButton.setTitle(VectorL10n.deviceVerificationSelfVerifyStartVerifyAction, for: .normal)
        self.verificationWaitingLabel.text = VectorL10n.deviceVerificationSelfVerifyStartWaiting
        self.informationLabel.text = VectorL10n.deviceVerificationSelfVerifyStartInformation
        self.additionalInformationLabel.text = nil
    }

    private func render(viewState: KeyVerificationSelfVerifyStartViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .loaded:
            self.renderLoaded()
        case .error(let error):
            self.render(error: error)
        case .verificationPending:
            self.renderVerificationPending()
        case .cancelled(let reason):
            self.renderCancelled(reason: reason)
        case .cancelledByMe(let reason):
            self.renderCancelledByMe(reason: reason)
        }
    }
    
    private func renderLoading() {
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
    }
    
    private func renderLoaded() {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
    }
    
    private func renderVerificationPending() {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.startVerificationButton.isHidden = true
        self.verificationWaitingLabel.isHidden = false
    }
    
    private func render(error: Error) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
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
    
    // MARK: - Actions

    @IBAction private func startVerificationButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .startVerification)
    }
    
    private func cancelButtonAction() {
        self.viewModel.process(viewAction: .cancel)
    }
}


// MARK: - KeyVerificationSelfVerifyStartViewModelViewDelegate
extension KeyVerificationSelfVerifyStartViewController: KeyVerificationSelfVerifyStartViewModelViewDelegate {

    func keyVerificationSelfVerifyStartViewModel(_ viewModel: KeyVerificationSelfVerifyStartViewModelType, didUpdateViewState viewSate: KeyVerificationSelfVerifyStartViewState) {
        self.render(viewState: viewSate)
    }
}
