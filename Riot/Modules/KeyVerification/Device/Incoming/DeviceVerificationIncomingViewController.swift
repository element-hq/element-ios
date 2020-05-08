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

    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var avatarImageView: MXKImageView!
    @IBOutlet weak var userDisplaynameLabel: UILabel!
    @IBOutlet weak var deviceIdLabel: UILabel!

    @IBOutlet weak var description1Label: UILabel!
    @IBOutlet weak var description2Label: UILabel!
    @IBOutlet weak var continueButtonBackgroundView: UIView!
    @IBOutlet weak var continueButton: UIButton!

    
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
        
        self.title = VectorL10n.keyVerificationOtherSessionTitle
        self.vc_removeBackTitle()
        
        self.setupViews()
        self.activityPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = MXKErrorAlertPresentation()
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        self.viewModel.viewDelegate = self
        self.viewModel.process(viewAction: .loadData)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.avatarImageView.layer.cornerRadius = avatarImageView.frame.size.width / 2
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
        self.description1Label.textColor = theme.textPrimaryColor
        self.description2Label.textColor = theme.textPrimaryColor
        self.userDisplaynameLabel.textColor = theme.textPrimaryColor
        self.deviceIdLabel.textColor = theme.textPrimaryColor
        
        self.continueButtonBackgroundView.backgroundColor = theme.backgroundColor
        theme.applyStyle(onButton: self.continueButton)
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
        
        self.scrollView.keyboardDismissMode = .interactive
        
        self.titleLabel.text = VectorL10n.deviceVerificationIncomingTitle
        self.description1Label.text = VectorL10n.deviceVerificationIncomingDescription1
        self.description2Label.text = VectorL10n.deviceVerificationIncomingDescription2
        self.continueButton.setTitle(VectorL10n.continue, for: .normal)

        if let avatarImageView = self.avatarImageView {
            let defaultavatarImage = AvatarGenerator.generateAvatar(forMatrixItem: self.viewModel.userId, withDisplayName: self.viewModel.userDisplayName)

            avatarImageView.enableInMemoryCache = true
            avatarImageView.setImageURI(self.viewModel.avatarUrl, withType: nil, andImageOrientation: .up, previewImage: defaultavatarImage, mediaManager: self.viewModel.mediaManager)

            avatarImageView.clipsToBounds = true
        }

        self.userDisplaynameLabel.text = self.viewModel.userDisplayName ?? self.viewModel.userId
        self.deviceIdLabel.text = self.viewModel.deviceId
    }

    private func render(viewState: DeviceVerificationIncomingViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .loaded:
            self.renderAccepted()
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
    
    private func renderAccepted() {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
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

    @IBAction private func continueButtonAction(_ sender: Any) {
         self.viewModel.process(viewAction: .accept)
    }

    private func cancelButtonAction() {
        self.viewModel.process(viewAction: .cancel)
    }
}


// MARK: - DeviceVerificationIncomingViewModelViewDelegate
extension DeviceVerificationIncomingViewController: DeviceVerificationIncomingViewModelViewDelegate {

    func deviceVerificationIncomingViewModel(_ viewModel: DeviceVerificationIncomingViewModelType, didUpdateViewState viewSate: DeviceVerificationIncomingViewState) {
        self.render(viewState: viewSate)
    }
}
