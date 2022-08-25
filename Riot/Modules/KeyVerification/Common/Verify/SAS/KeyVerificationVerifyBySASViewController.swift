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

    @IBOutlet private var scrollView: UIScrollView!

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var informationLabel: UILabel!
    @IBOutlet private var decimalLabel: UILabel!
    @IBOutlet private var emojisCollectionView: UICollectionView!
    @IBOutlet private var waitingPartnerLabel: UILabel!
    
    @IBOutlet private var buttonsStackView: UIStackView!
    @IBOutlet private var cancelButton: RoundedButton!
    @IBOutlet private var validateButton: RoundedButton!
    @IBOutlet private var additionalInformationLabel: UILabel!
    
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
        
        vc_removeBackTitle()
        
        setupViews()
        errorPresenter = MXKErrorAlertPresentation()
        activityPresenter = ActivityIndicatorPresenter()
        
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
        informationLabel.textColor = theme.textPrimaryColor
        decimalLabel.textColor = theme.textPrimaryColor
        waitingPartnerLabel.textColor = theme.textPrimaryColor

        cancelButton.update(theme: theme)
        validateButton.update(theme: theme)

        emojisCollectionView.reloadData()
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
            self?.cancelAction()
        }
        
        navigationItem.rightBarButtonItem = cancelBarButtonItem
        
        scrollView.keyboardDismissMode = .interactive

        let isVerificationByEmoji = viewModel.emojis != nil
        
        if isVerificationByEmoji {
            decimalLabel.isHidden = true
        } else {
            emojisCollectionView.isHidden = true
            decimalLabel.text = viewModel.decimal
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

        title = viewModel.verificationKind.verificationTitle
        titleLabel.text = instructionText
        informationLabel.text = adviceText
        waitingPartnerLabel.text = VectorL10n.deviceVerificationVerifyWaitPartner

        waitingPartnerLabel.isHidden = true

        cancelButton.setTitle(VectorL10n.keyVerificationVerifySasCancelAction, for: .normal)
        cancelButton.actionStyle = .cancel
        validateButton.setTitle(VectorL10n.keyVerificationVerifySasValidateAction, for: .normal)
        
        additionalInformationLabel.text = VectorL10n.keyVerificationVerifySasAdditionalInformation
    }

    private func render(viewState: KeyVerificationVerifyViewState) {
        switch viewState {
        case .loading:
            renderLoading()
        case .loaded:
            renderVerified()
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
    
    private func renderVerified() {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        
        buttonsStackView.isHidden = true
        waitingPartnerLabel.isHidden = false
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

    private func cancelAction() {
        viewModel.process(viewAction: .cancel)
    }
    
    @IBAction private func cancelButtonAction(_ sender: Any) {
        cancelAction()
    }
    
    @IBAction private func validateButtonAction(_ sender: Any) {
        viewModel.process(viewAction: .confirm)
    }
}

// MARK: - DeviceVerificationVerifyViewModelViewDelegate

extension KeyVerificationVerifyBySASViewController: KeyVerificationVerifyBySASViewModelViewDelegate {
    func keyVerificationVerifyBySASViewModel(_ viewModel: KeyVerificationVerifyBySASViewModelType, didUpdateViewState viewSate: KeyVerificationVerifyViewState) {
        render(viewState: viewSate)
    }
}

extension KeyVerificationVerifyBySASViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let emojis = viewModel.emojis else {
            return 0
        }
        return emojis.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath, cellType: VerifyEmojiCollectionViewCell.self)

        guard let emoji = viewModel.emojis?[indexPath.row] else {
            return UICollectionViewCell()
        }

        cell.emoji.text = emoji.emoji
        cell.name.text = VectorL10n.tr("Vector", "device_verification_emoji_\(emoji.name)")
        
        cell.update(theme: theme)

        return cell
    }
}
