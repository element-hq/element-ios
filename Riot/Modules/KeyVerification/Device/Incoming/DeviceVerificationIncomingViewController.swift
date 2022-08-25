// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Incoming DeviceVerificationIncoming
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

final class DeviceVerificationIncomingViewController: UIViewController {
    // MARK: - Constants
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private var scrollView: UIScrollView!
    
    @IBOutlet var titleLabel: UILabel!

    @IBOutlet var avatarImageView: MXKImageView!
    @IBOutlet var userDisplaynameLabel: UILabel!
    @IBOutlet var deviceIdLabel: UILabel!

    @IBOutlet var description1Label: UILabel!
    @IBOutlet var description2Label: UILabel!
    @IBOutlet var continueButtonBackgroundView: UIView!
    @IBOutlet var continueButton: UIButton!

    // MARK: Private

    private var viewModel: DeviceVerificationIncomingViewModelType!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!

    // MARK: - Setup
    
    class func instantiate(with viewModel: DeviceVerificationIncomingViewModelType) -> DeviceVerificationIncomingViewController {
        let viewController = StoryboardScene.DeviceVerificationIncomingViewController.initialScene.instantiate()
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
        viewModel.process(viewAction: .loadData)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        avatarImageView.layer.cornerRadius = avatarImageView.frame.size.width / 2
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
        description1Label.textColor = theme.textPrimaryColor
        description2Label.textColor = theme.textPrimaryColor
        userDisplaynameLabel.textColor = theme.textPrimaryColor
        deviceIdLabel.textColor = theme.textPrimaryColor
        
        continueButtonBackgroundView.backgroundColor = theme.backgroundColor
        theme.applyStyle(onButton: continueButton)
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
        
        titleLabel.text = VectorL10n.deviceVerificationIncomingTitle
        description1Label.text = VectorL10n.deviceVerificationIncomingDescription1
        description2Label.text = VectorL10n.deviceVerificationIncomingDescription2
        continueButton.setTitle(VectorL10n.continue, for: .normal)

        if let avatarImageView = avatarImageView {
            let defaultavatarImage = AvatarGenerator.generateAvatar(forMatrixItem: viewModel.userId, withDisplayName: viewModel.userDisplayName)

            avatarImageView.enableInMemoryCache = true
            avatarImageView.setImageURI(viewModel.avatarUrl, withType: nil, andImageOrientation: .up, previewImage: defaultavatarImage, mediaManager: viewModel.mediaManager)

            avatarImageView.clipsToBounds = true
        }

        userDisplaynameLabel.text = viewModel.userDisplayName ?? viewModel.userId
        deviceIdLabel.text = viewModel.deviceId
    }

    private func render(viewState: DeviceVerificationIncomingViewState) {
        switch viewState {
        case .loading:
            renderLoading()
        case .loaded:
            renderAccepted()
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
    
    private func renderAccepted() {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
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

    @IBAction private func continueButtonAction(_ sender: Any) {
        viewModel.process(viewAction: .accept)
    }

    private func cancelButtonAction() {
        viewModel.process(viewAction: .cancel)
    }
}

// MARK: - DeviceVerificationIncomingViewModelViewDelegate

extension DeviceVerificationIncomingViewController: DeviceVerificationIncomingViewModelViewDelegate {
    func deviceVerificationIncomingViewModel(_ viewModel: DeviceVerificationIncomingViewModelType, didUpdateViewState viewSate: DeviceVerificationIncomingViewState) {
        render(viewState: viewSate)
    }
}
