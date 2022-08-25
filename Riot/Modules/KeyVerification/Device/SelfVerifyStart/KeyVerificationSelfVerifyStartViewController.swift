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

    @IBOutlet private var informationLabel: UILabel!
    
    @IBOutlet private var startVerificationButton: UIButton!
    @IBOutlet private var verificationWaitingLabel: UILabel!
    
    @IBOutlet private var additionalInformationLabel: UILabel!
    
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
        
        title = VectorL10n.keyVerificationNewSessionTitle
        
        setupViews()
        activityPresenter = ActivityIndicatorPresenter()
        errorPresenter = MXKErrorAlertPresentation()
        
        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
        
        viewModel.viewDelegate = self

        viewModel.process(viewAction: .loadData)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navigationController = navigationController {
            if navigationController.navigationBar.isHidden == true {
                navigationItem.hidesBackButton = true
                // Show navigation bar if needed
                navigationController.setNavigationBarHidden(false, animated: animated)
            } else {
                // Hide back button
                navigationItem.setHidesBackButton(true, animated: animated)
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        startVerificationButton.layer.cornerRadius = Constants.verifyButtonCornerRadius
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
        startVerificationButton.vc_setBackgroundColor(theme.tintColor, for: .normal)
        verificationWaitingLabel.textColor = theme.textSecondaryColor
        additionalInformationLabel.textColor = theme.textSecondaryColor
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
        
        startVerificationButton.layer.masksToBounds = true
        startVerificationButton.setTitle(VectorL10n.deviceVerificationSelfVerifyStartVerifyAction, for: .normal)
        verificationWaitingLabel.text = VectorL10n.deviceVerificationSelfVerifyStartWaiting
        informationLabel.text = VectorL10n.deviceVerificationSelfVerifyStartInformation
        additionalInformationLabel.text = nil
    }

    private func render(viewState: KeyVerificationSelfVerifyStartViewState) {
        switch viewState {
        case .loading:
            renderLoading()
        case .loaded:
            renderLoaded()
        case .error(let error):
            render(error: error)
        case .verificationPending:
            renderVerificationPending()
        case .cancelled(let reason):
            renderCancelled(reason: reason)
        case .cancelledByMe(let reason):
            renderCancelledByMe(reason: reason)
        }
    }
    
    private func renderLoading() {
        activityPresenter.presentActivityIndicator(on: view, animated: true)
    }
    
    private func renderLoaded() {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
    }
    
    private func renderVerificationPending() {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        startVerificationButton.isHidden = true
        verificationWaitingLabel.isHidden = false
    }
    
    private func render(error: Error) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
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
    
    // MARK: - Actions

    @IBAction private func startVerificationButtonAction(_ sender: Any) {
        viewModel.process(viewAction: .startVerification)
    }
    
    private func cancelButtonAction() {
        viewModel.process(viewAction: .cancel)
    }
}

// MARK: - KeyVerificationSelfVerifyStartViewModelViewDelegate

extension KeyVerificationSelfVerifyStartViewController: KeyVerificationSelfVerifyStartViewModelViewDelegate {
    func keyVerificationSelfVerifyStartViewModel(_ viewModel: KeyVerificationSelfVerifyStartViewModelType, didUpdateViewState viewSate: KeyVerificationSelfVerifyStartViewState) {
        render(viewState: viewSate)
    }
}
