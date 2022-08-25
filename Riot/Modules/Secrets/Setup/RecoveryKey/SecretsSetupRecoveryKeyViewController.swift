// File created from ScreenTemplate
// $ createScreen.sh SecretsSetupRecoveryKey SecretsSetupRecoveryKey
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

final class SecretsSetupRecoveryKeyViewController: UIViewController {
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private var secureKeyImageView: UIImageView!
    @IBOutlet private var informationLabel: UILabel!
    @IBOutlet private var recoveryKeyLabel: UILabel!
    @IBOutlet private var exportButton: RoundedButton!
    @IBOutlet private var doneButton: RoundedButton!
    
    // MARK: Private

    private var viewModel: SecretsSetupRecoveryKeyViewModelType!
    private var isPassphraseOnly = true
    private var cancellable: Bool!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    
    private var recoveryKey: String?
    private var hasSavedRecoveryKey = false

    // MARK: - Setup
    
    class func instantiate(with viewModel: SecretsSetupRecoveryKeyViewModelType, cancellable: Bool) -> SecretsSetupRecoveryKeyViewController {
        let viewController = StoryboardScene.SecretsSetupRecoveryKeyViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.cancellable = cancellable
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
        
        secureKeyImageView.tintColor = theme.textPrimaryColor
        informationLabel.textColor = theme.textPrimaryColor
        recoveryKeyLabel.textColor = theme.textSecondaryColor
        
        exportButton.update(theme: theme)
        doneButton.update(theme: theme)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        if cancellable {
            let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
                self?.cancelButtonAction()
            }

            navigationItem.rightBarButtonItem = cancelBarButtonItem
        }

        vc_removeBackTitle()
        
        title = VectorL10n.secretsSetupRecoveryKeyTitle
        
        secureKeyImageView.image = Asset.Images.secretsSetupKey.image.withRenderingMode(.alwaysTemplate)
        informationLabel.text = VectorL10n.secretsSetupRecoveryKeyInformation
        recoveryKeyLabel.text = VectorL10n.secretsSetupRecoveryKeyLoading
        
        exportButton.setTitle(VectorL10n.secretsSetupRecoveryKeyExportAction, for: .normal)
        exportButton.isEnabled = false
        doneButton.setTitle(VectorL10n.continue, for: .normal)
        
        updateDoneButton()
    }

    private func render(viewState: SecretsSetupRecoveryKeyViewState) {
        switch viewState {
        case .loading:
            renderLoading()
        case .loaded(let passphraseOnly):
            renderLoaded(passphraseOnly: passphraseOnly)
        case .recoveryCreated(let recoveryKey):
            renderRecoveryCreated(recoveryKey: recoveryKey)
        case .error(let error):
            render(error: error)
        }
    }
    
    private func renderLoaded(passphraseOnly: Bool) {
        isPassphraseOnly = passphraseOnly

        let title: String
        let secretsLogoImage: UIImage
        let informationText: String
        let recoveryKeyText: String?

        if passphraseOnly {
            title = VectorL10n.secretsSetupRecoveryPassphraseSummaryTitle
            secretsLogoImage = Asset.Images.secretsSetupPassphrase.image
            informationText = VectorL10n.secretsSetupRecoveryPassphraseSummaryInformation
            recoveryKeyText = nil
        } else {
            title = VectorL10n.secretsSetupRecoveryKeyTitle
            secretsLogoImage = Asset.Images.secretsSetupKey.image
            informationText = VectorL10n.secretsSetupRecoveryKeyInformation
            recoveryKeyText = VectorL10n.secretsSetupRecoveryKeyLoading
        }

        self.title = title
        secureKeyImageView.image = secretsLogoImage
        informationLabel.text = informationText
        exportButton.isHidden = passphraseOnly
        recoveryKeyLabel.text = recoveryKeyText
    }
    
    private func renderLoading() {
        activityPresenter.presentActivityIndicator(on: view, animated: true)
    }
    
    private func renderRecoveryCreated(recoveryKey: String) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        
        exportButton.isEnabled = !isPassphraseOnly
        doneButton.isEnabled = isPassphraseOnly
        
        if !isPassphraseOnly {
            self.recoveryKey = recoveryKey
            recoveryKeyLabel.text = recoveryKey
        }
    }
    
    private func render(error: Error) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        errorPresenter.presentError(from: self, forError: error, animated: true) {
            self.viewModel.process(viewAction: .errorAlertOk)
        }
    }
    
    private func updateDoneButton() {
        doneButton.isEnabled = hasSavedRecoveryKey
    }
    
    private func presentKeepSafeAlert() {
        let alertController = UIAlertController(title: VectorL10n.secretsSetupRecoveryKeyStorageAlertTitle,
                                                message: VectorL10n.secretsSetupRecoveryKeyStorageAlertMessage,
                                                preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: VectorL10n.continue, style: .cancel, handler: { _ in
            self.viewModel.process(viewAction: .done)
        }))
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func shareRecoveryKey() {
        guard let recoveryKey = recoveryKey else {
            return
        }
        
        // Set up activity view controller
        let activityItems: [Any] = [recoveryKey]
        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        activityViewController.completionWithItemsHandler = { _, completed, _, _ in
            
            // Enable made copy button only if user has selected an activity item and has setup recovery key without passphrase
            if completed {
                self.hasSavedRecoveryKey = true
                self.updateDoneButton()
            }
        }
        
        // Configure source view when activity view controller is presented with a popover
        if let popoverPresentationController = activityViewController.popoverPresentationController {
            popoverPresentationController.sourceView = exportButton
            popoverPresentationController.sourceRect = exportButton.bounds
            popoverPresentationController.permittedArrowDirections = [.down, .up]
        }
        
        present(activityViewController, animated: true)
    }
    
    // MARK: - Actions

    @IBAction private func exportButtonAction(_ sender: Any) {
        shareRecoveryKey()
    }
    
    @IBAction private func doneButtonAction(_ sender: Any) {
        if isPassphraseOnly {
            viewModel.process(viewAction: .done)
        } else {
            presentKeepSafeAlert()
        }
    }

    private func cancelButtonAction() {
        viewModel.process(viewAction: .cancel)
    }
}

// MARK: - SecretsSetupRecoveryKeyViewModelViewDelegate

extension SecretsSetupRecoveryKeyViewController: SecretsSetupRecoveryKeyViewModelViewDelegate {
    func secretsSetupRecoveryKeyViewModel(_ viewModel: SecretsSetupRecoveryKeyViewModelType, didUpdateViewState viewSate: SecretsSetupRecoveryKeyViewState) {
        render(viewState: viewSate)
    }
}
