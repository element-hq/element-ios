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

    @IBOutlet private var scrollView: UIScrollView!
    
    @IBOutlet private var titleLabel: UILabel!
    
    @IBOutlet private var waitingLabel: UILabel!
    
    @IBOutlet private var scannedContentView: UIView!
    @IBOutlet private var scannedInformationLabel: UILabel!
    @IBOutlet private var rejectButton: RoundedButton!
    @IBOutlet private var confirmButton: RoundedButton!
    
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
        
        // Hide back button
        navigationItem.setHidesBackButton(true, animated: animated)
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
        waitingLabel.textColor = theme.textSecondaryColor
        scannedInformationLabel.textColor = theme.textPrimaryColor
        confirmButton.update(theme: theme)
        rejectButton.update(theme: theme)
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
        
        confirmButton.layer.masksToBounds = true
        rejectButton.layer.masksToBounds = true
        
        confirmButton.setTitle(VectorL10n.yes, for: .normal)
        rejectButton.setTitle(VectorL10n.no, for: .normal)
        rejectButton.actionStyle = .cancel
    }

    private func render(viewState: KeyVerificationScanConfirmationViewState) {
        switch viewState {
        case .loading:
            renderLoading()
        case .loaded(let viewData):
            renderLoaded(viewData: viewData)
        case .error(let error):
            render(error: error)
        case .cancelled(let reason):
            renderCancelled(reason: reason)
        case .cancelledByMe(let reason):
            renderCancelledByMe(reason: reason)
        }
    }
    
    private func renderLoading() {
        activityPresenter.presentActivityIndicator(on: view, animated: true)
    }
    
    private func renderLoaded(viewData: KeyVerificationScanConfirmationViewData) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)

        waitingLabel.isHidden = !viewData.isScanning
        scannedContentView.isHidden = viewData.isScanning
        
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
        titleLabel.text = title
        waitingLabel.text = waitingInfo
        scannedInformationLabel.text = scannedInfo
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

    @IBAction private func rejectButtonAction(_ sender: Any) {
        viewModel.process(viewAction: .acknowledgeOtherScannedMyCode(false))
    }
    
    @IBAction private func confirmButtonAction(_ sender: Any) {
        viewModel.process(viewAction: .acknowledgeOtherScannedMyCode(true))
    }

    private func cancelButtonAction() {
        viewModel.process(viewAction: .cancel)
    }
}

// MARK: - KeyVerificationScanConfirmationViewModelViewDelegate

extension KeyVerificationScanConfirmationViewController: KeyVerificationScanConfirmationViewModelViewDelegate {
    func keyVerificationScanConfirmationViewModel(_ viewModel: KeyVerificationScanConfirmationViewModelType, didUpdateViewState viewSate: KeyVerificationScanConfirmationViewState) {
        render(viewState: viewSate)
    }
}
