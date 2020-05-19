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
    
    @IBOutlet private weak var informationLabel: UILabel!
    
    @IBOutlet private weak var desktopClientImageView: UIImageView!
    @IBOutlet private weak var desktopClientLabel: UILabel!
    
    @IBOutlet private weak var mobileClientImageView: UIImageView!
    @IBOutlet private weak var mobileClientLabel: UILabel!
    
    @IBOutlet private weak var additionalInformationLabel: UILabel!
    
    // MARK: Private

    private var viewModel: KeyVerificationSelfVerifyWaitViewModelType!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    
    private weak var cancelBarButtonItem: UIBarButtonItem?

    // MARK: - Setup
    
    class func instantiate(with viewModel: KeyVerificationSelfVerifyWaitViewModelType) -> KeyVerificationSelfVerifyWaitViewController {
        let viewController = StoryboardScene.KeyVerificationSelfVerifyWaitViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.setupViews()
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
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        self.informationLabel.textColor = theme.textPrimaryColor
        self.desktopClientLabel.textColor = theme.textPrimaryColor
        self.desktopClientImageView.tintColor = theme.tintColor
        self.mobileClientLabel.textColor = theme.textPrimaryColor
        self.mobileClientImageView.tintColor = theme.tintColor
        self.additionalInformationLabel.textColor = theme.textSecondaryColor
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.skip, style: .plain) { [weak self] in
            self?.cancelButtonAction()
        }
        
        self.navigationItem.rightBarButtonItem = cancelBarButtonItem
        self.cancelBarButtonItem = cancelBarButtonItem
        
        self.title = VectorL10n.deviceVerificationSelfVerifyWaitTitle
        
        self.informationLabel.text = VectorL10n.deviceVerificationSelfVerifyWaitInformation
        self.desktopClientLabel.vc_setText("\(VectorL10n.clientWebName)\n\(VectorL10n.clientDesktopName)", withLineSpacing: Constants.clientNamesLineSpacing, alignement: .center)
        self.mobileClientLabel.vc_setText("\(VectorL10n.clientIosName)\n\(VectorL10n.clientAndroidName)",
            withLineSpacing: Constants.clientNamesLineSpacing, alignement: .center)
        
        self.desktopClientImageView.image = Asset.Images.monitor.image.withRenderingMode(.alwaysTemplate)
        self.mobileClientImageView.image = Asset.Images.smartphone.image.withRenderingMode(.alwaysTemplate)
        
        self.additionalInformationLabel.text = VectorL10n.deviceVerificationSelfVerifyWaitAdditionalInformation
    }

    private func render(viewState: KeyVerificationSelfVerifyWaitViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .loaded(let isNewSignIn):
            self.renderLoaded(isNewSignIn: isNewSignIn)
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
    
    private func renderLoaded(isNewSignIn: Bool) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        
        self.title = isNewSignIn ? VectorL10n.deviceVerificationSelfVerifyWaitNewSignInTitle : VectorL10n.deviceVerificationSelfVerifyWaitTitle
        self.cancelBarButtonItem?.title = isNewSignIn ? VectorL10n.skip : VectorL10n.cancel
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
    
    private func cancelButtonAction() {
        self.viewModel.process(viewAction: .cancel)
    }
}


// MARK: - KeyVerificationSelfVerifyWaitViewModelViewDelegate
extension KeyVerificationSelfVerifyWaitViewController: KeyVerificationSelfVerifyWaitViewModelViewDelegate {

    func keyVerificationSelfVerifyWaitViewModel(_ viewModel: KeyVerificationSelfVerifyWaitViewModelType, didUpdateViewState viewSate: KeyVerificationSelfVerifyWaitViewState) {
        self.render(viewState: viewSate)
    }
}
