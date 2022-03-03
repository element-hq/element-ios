// File created from ScreenTemplate
// $ createScreen.sh KeyVerification/Common/ScanConfirmation KeyVerificationScanConfirmation
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

final class KeyVerificationScanConfirmationViewController: UIViewController {
    
    // MARK: - Constants
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var titleLabel: UILabel!
    
    @IBOutlet private weak var waitingLabel: UILabel!
    
    @IBOutlet private weak var scannedContentView: UIView!
    @IBOutlet private weak var scannedInformationLabel: UILabel!
    @IBOutlet private weak var rejectButton: RoundedButton!
    @IBOutlet private weak var confirmButton: RoundedButton!
    
    // MARK: Private

    private var viewModel: KeyVerificationScanConfirmationViewModelType!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!

    // MARK: - Setup
    
    class func instantiate(with viewModel: KeyVerificationScanConfirmationViewModelType) -> KeyVerificationScanConfirmationViewController {
        let viewController = StoryboardScene.KeyVerificationScanConfirmationViewController.initialScene.instantiate()
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide back button
        self.navigationItem.setHidesBackButton(true, animated: animated)
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
        self.waitingLabel.textColor = theme.textSecondaryColor
        self.scannedInformationLabel.textColor = theme.textPrimaryColor
        self.confirmButton.update(theme: theme)
        self.rejectButton.update(theme: theme)
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
        
        self.confirmButton.layer.masksToBounds = true
        self.rejectButton.layer.masksToBounds = true
        
        self.confirmButton.setTitle(VectorL10n.yes, for: .normal)
        self.rejectButton.setTitle(VectorL10n.no, for: .normal)
        self.rejectButton.actionStyle = .cancel
    }

    private func render(viewState: KeyVerificationScanConfirmationViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .loaded(let viewData):
            self.renderLoaded(viewData: viewData)
        case .error(let error):
            self.render(error: error)
        case .cancelled(let reason):
            self.renderCancelled(reason: reason)
        case .cancelledByMe(let reason):
            self.renderCancelledByMe(reason: reason)
        }
    }
    
    private func renderLoading() {
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
    }
    
    private func renderLoaded(viewData: KeyVerificationScanConfirmationViewData) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)

        self.waitingLabel.isHidden = !viewData.isScanning
        self.scannedContentView.isHidden = viewData.isScanning
        
        var title: String
        var waitingInfo: String?
        var scannedInfo: String?
        
        if viewData.isScanning {
            title = VectorL10n.keyVerificationScanConfirmationScanningTitle
            
            switch viewData.verificationKind {
            case .otherSession, .thisSession, .newSession:
                waitingInfo = VectorL10n.keyVerificationScanConfirmationScanningDeviceWaitingOther
            case .user:
                waitingInfo = VectorL10n.keyVerificationScanConfirmationScanningUserWaitingOther(viewData.otherDisplayName)
            }
        } else {
            title = VectorL10n.keyVerificationScanConfirmationScannedTitle
            
            switch viewData.verificationKind {
            case .otherSession, .thisSession, .newSession:
                scannedInfo = VectorL10n.keyVerificationScanConfirmationScannedDeviceInformation
            case .user:
                scannedInfo = VectorL10n.keyVerificationScanConfirmationScannedUserInformation(viewData.otherDisplayName)
            }
        }
        
        self.title = viewData.verificationKind.verificationTitle
        self.titleLabel.text = title
        self.waitingLabel.text = waitingInfo
        self.scannedInformationLabel.text = scannedInfo
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

    @IBAction private func rejectButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .acknowledgeOtherScannedMyCode(false))
    }
    
    @IBAction private func confirmButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .acknowledgeOtherScannedMyCode(true))
    }

    private func cancelButtonAction() {
        self.viewModel.process(viewAction: .cancel)
    }
}


// MARK: - KeyVerificationScanConfirmationViewModelViewDelegate
extension KeyVerificationScanConfirmationViewController: KeyVerificationScanConfirmationViewModelViewDelegate {

    func keyVerificationScanConfirmationViewModel(_ viewModel: KeyVerificationScanConfirmationViewModelType, didUpdateViewState viewSate: KeyVerificationScanConfirmationViewState) {
        self.render(viewState: viewSate)
    }
}
