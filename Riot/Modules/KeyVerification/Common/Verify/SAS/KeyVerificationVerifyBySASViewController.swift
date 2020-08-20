// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Verify DeviceVerificationVerify
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

final class KeyVerificationVerifyBySASViewController: UIViewController {

    // MARK: - Constants
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private weak var scrollView: UIScrollView!

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var informationLabel: UILabel!
    @IBOutlet private weak var decimalLabel: UILabel!
    @IBOutlet private weak var emojisCollectionView: UICollectionView!
    @IBOutlet private weak var waitingPartnerLabel: UILabel!
    
    @IBOutlet private weak var buttonsStackView: UIStackView!
    @IBOutlet private weak var cancelButton: RoundedButton!
    @IBOutlet private weak var validateButton: RoundedButton!
    @IBOutlet private weak var additionalInformationLabel: UILabel!
    
    // MARK: Private

    private var viewModel: KeyVerificationVerifyBySASViewModelType!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!

    // MARK: - Setup
    
    class func instantiate(with viewModel: KeyVerificationVerifyBySASViewModelType) -> KeyVerificationVerifyBySASViewController {
        let viewController = StoryboardScene.KeyVerificationVerifyBySASViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.vc_removeBackTitle()
        
        self.setupViews()
        self.errorPresenter = MXKErrorAlertPresentation()
        self.activityPresenter = ActivityIndicatorPresenter()
        
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
        self.informationLabel.textColor = theme.textPrimaryColor
        self.decimalLabel.textColor = theme.textPrimaryColor
        self.waitingPartnerLabel.textColor = theme.textPrimaryColor

        self.cancelButton.update(theme: theme)
        self.validateButton.update(theme: theme)

        emojisCollectionView.reloadData()
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
            self?.cancelAction()
        }
        
        self.navigationItem.rightBarButtonItem = cancelBarButtonItem
        
        self.scrollView.keyboardDismissMode = .interactive

        let isVerificationByEmoji = viewModel.emojis != nil
        
        if isVerificationByEmoji {
            self.decimalLabel.isHidden = true
        } else {
            self.emojisCollectionView.isHidden = true
            self.decimalLabel.text = self.viewModel.decimal
        }
        
        let instructionText: String
        let adviceText: String
        
        if isVerificationByEmoji {
            instructionText = VectorL10n.keyVerificationVerifySasTitleEmoji
            adviceText = VectorL10n.deviceVerificationSecurityAdviceEmoji
        } else {
            instructionText = VectorL10n.keyVerificationVerifySasTitleNumber
            adviceText = VectorL10n.deviceVerificationSecurityAdviceNumber
        }

        self.title = self.viewModel.verificationKind.verificationTitle
        self.titleLabel.text = instructionText
        self.informationLabel.text = adviceText
        self.waitingPartnerLabel.text = VectorL10n.deviceVerificationVerifyWaitPartner

        self.waitingPartnerLabel.isHidden = true

        self.cancelButton.setTitle(VectorL10n.keyVerificationVerifySasCancelAction, for: .normal)
        self.cancelButton.actionStyle = .cancel
        self.validateButton.setTitle(VectorL10n.keyVerificationVerifySasValidateAction, for: .normal)
        
        self.additionalInformationLabel.text = VectorL10n.keyVerificationVerifySasAdditionalInformation
    }

    private func render(viewState: KeyVerificationVerifyViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .loaded:
            self.renderVerified()
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
    
    private func renderVerified() {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        
        self.buttonsStackView.isHidden = true
        self.waitingPartnerLabel.isHidden = false
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

    private func cancelAction() {
        self.viewModel.process(viewAction: .cancel)
    }
    
    @IBAction private func cancelButtonAction(_ sender: Any) {
        self.cancelAction()
    }
    
    @IBAction private func validateButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .confirm)
    }
}


// MARK: - DeviceVerificationVerifyViewModelViewDelegate
extension KeyVerificationVerifyBySASViewController: KeyVerificationVerifyBySASViewModelViewDelegate {

    func keyVerificationVerifyBySASViewModel(_ viewModel: KeyVerificationVerifyBySASViewModelType, didUpdateViewState viewSate: KeyVerificationVerifyViewState) {
        self.render(viewState: viewSate)
    }
}


extension KeyVerificationVerifyBySASViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let emojis = self.viewModel.emojis else {
            return 0
        }
        return emojis.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(for: indexPath, cellType: VerifyEmojiCollectionViewCell.self)

        guard let emoji = self.viewModel.emojis?[indexPath.row] else {
            return UICollectionViewCell()
        }

        cell.emoji.text = emoji.emoji
        cell.name.text =  VectorL10n.tr("Vector", "device_verification_emoji_\(emoji.name)")
        
        cell.update(theme: self.theme)

        return cell
    }
}
