// File created from ScreenTemplate
// $ createScreen.sh Start UserVerificationStart
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

final class UserVerificationStartViewController: UIViewController {
    // MARK: - Constants
    
    private enum Constants {
        static let verifyButtonCornerRadius: CGFloat = 8.0
        static let informationTextDefaultFont = UIFont.systemFont(ofSize: 15.0)
        static let informationTextBoldFont = UIFont.systemFont(ofSize: 15.0, weight: .medium)
    }
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private var informationLabel: UILabel!
    
    @IBOutlet private var startVerificationButton: UIButton!
    @IBOutlet private var verificationWaitingLabel: UILabel!
    
    @IBOutlet private var additionalInformationLabel: UILabel!
    
    // MARK: Private

    private var viewModel: UserVerificationStartViewModelType!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!

    // MARK: - Setup
    
    class func instantiate(with viewModel: UserVerificationStartViewModelType) -> UserVerificationStartViewController {
        let viewController = StoryboardScene.UserVerificationStartViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        title = VectorL10n.keyVerificationUserTitle
        
        setupViews()
        
        activityPresenter = ActivityIndicatorPresenter()
        errorPresenter = MXKErrorAlertPresentation()
        
        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
        
        viewModel.viewDelegate = self

        viewModel.process(viewAction: .loadData)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        self.theme.statusBarStyle
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        startVerificationButton.layer.cornerRadius = Constants.verifyButtonCornerRadius
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
        startVerificationButton.setTitle(VectorL10n.userVerificationStartVerifyAction, for: .normal)
        additionalInformationLabel.text = VectorL10n.userVerificationStartAdditionalInformation
    }

    private func render(viewState: UserVerificationStartViewState) {
        switch viewState {
        case .loading:
            renderLoading()
        case .loaded(let viewData):
            renderLoaded(viewData: viewData)
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
    
    private func renderLoaded(viewData: UserVerificationStartViewData) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        
        informationLabel.attributedText = buildInformationAttributedText(with: viewData.userId)
        verificationWaitingLabel.text = buildVerificationWaitingText(with: viewData)
    }
    
    private func render(error: Error) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }
    
    private func renderVerificationPending() {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        startVerificationButton.isHidden = true
        verificationWaitingLabel.isHidden = false
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
    
    private func buildInformationAttributedText(with userId: String) -> NSAttributedString {
        let informationAttributedText = NSMutableAttributedString()
        
        let informationTextDefaultAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: theme.textPrimaryColor,
                                                                               .font: Constants.informationTextDefaultFont]
        
        let informationTextBoldAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: theme.textPrimaryColor,
                                                                            .font: Constants.informationTextBoldFont]
        
        let informationAttributedStringPart1 = NSAttributedString(string: VectorL10n.userVerificationStartInformationPart1, attributes: informationTextDefaultAttributes)
        let informationAttributedStringPart2 = NSAttributedString(string: userId, attributes: informationTextBoldAttributes)
        let informationAttributedStringPart3 = NSAttributedString(string: VectorL10n.userVerificationStartInformationPart2, attributes: informationTextDefaultAttributes)
        
        informationAttributedText.append(informationAttributedStringPart1)
        informationAttributedText.append(informationAttributedStringPart2)
        informationAttributedText.append(informationAttributedStringPart3)
        
        return informationAttributedText
    }
    
    private func buildVerificationWaitingText(with viewData: UserVerificationStartViewData) -> String {
        let userName = viewData.userDisplayName ?? viewData.userId
        return VectorL10n.userVerificationStartWaitingPartner(userName)
    }
    
    // MARK: - Actions

    @IBAction private func startVerificationButtonAction(_ sender: Any) {
        viewModel.process(viewAction: .startVerification)
    }

    private func cancelButtonAction() {
        viewModel.process(viewAction: .cancel)
    }
}

// MARK: - UserVerificationStartViewModelViewDelegate

extension UserVerificationStartViewController: UserVerificationStartViewModelViewDelegate {
    func userVerificationStartViewModel(_ viewModel: UserVerificationStartViewModelType, didUpdateViewState viewSate: UserVerificationStartViewState) {
        render(viewState: viewSate)
    }
}
