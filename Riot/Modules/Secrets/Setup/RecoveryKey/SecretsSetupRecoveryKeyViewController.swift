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
    
    @IBOutlet private weak var secureKeyImageView: UIImageView!
    @IBOutlet private weak var informationLabel: UILabel!
    @IBOutlet private weak var recoveryKeyLabel: UILabel!
    @IBOutlet private weak var exportButton: RoundedButton!
    @IBOutlet private weak var doneButton: RoundedButton!
    
    // MARK: Private

    private var viewModel: SecretsSetupRecoveryKeyViewModelType!
    private var isPassphraseOnly: Bool = true
    private var cancellable: Bool!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    
    private var recoveryKey: String?
    private var hasSavedRecoveryKey: Bool = false

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
        
        self.secureKeyImageView.tintColor = theme.textPrimaryColor
        self.informationLabel.textColor = theme.textPrimaryColor
        self.recoveryKeyLabel.textColor = theme.textSecondaryColor
        
        self.exportButton.update(theme: theme)
        self.doneButton.update(theme: theme)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        if self.cancellable {
            let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
                self?.cancelButtonAction()
            }

            self.navigationItem.rightBarButtonItem = cancelBarButtonItem
        }

        self.vc_removeBackTitle()                
        
        self.title = VectorL10n.secretsSetupRecoveryKeyTitle
        
        self.secureKeyImageView.image = Asset.Images.secretsSetupKey.image.withRenderingMode(.alwaysTemplate)
        self.informationLabel.text = VectorL10n.secretsSetupRecoveryKeyInformation
        self.recoveryKeyLabel.text = VectorL10n.secretsSetupRecoveryKeyLoading
        
        self.exportButton.setTitle(VectorL10n.secretsSetupRecoveryKeyExportAction, for: .normal)
        self.exportButton.isEnabled = false
        self.doneButton.setTitle(VectorL10n.continue, for: .normal)
        
        self.updateDoneButton()
    }

    private func render(viewState: SecretsSetupRecoveryKeyViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .loaded(let passphraseOnly):
            self.renderLoaded(passphraseOnly: passphraseOnly)
        case .recoveryCreated(let recoveryKey):
            self.renderRecoveryCreated(recoveryKey: recoveryKey)
        case .error(let error):
            self.render(error: error)
        }
    }
    
    private func renderLoaded(passphraseOnly: Bool) {        
        self.isPassphraseOnly = passphraseOnly

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
        self.secureKeyImageView.image = secretsLogoImage
        self.informationLabel.text = informationText
        self.exportButton.isHidden = passphraseOnly
        self.recoveryKeyLabel.text = recoveryKeyText
    }
    
    private func renderLoading() {
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
    }
    
    private func renderRecoveryCreated(recoveryKey: String) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        
        self.exportButton.isEnabled = !self.isPassphraseOnly
        self.doneButton.isEnabled = self.isPassphraseOnly
        
        if !self.isPassphraseOnly {
            self.recoveryKey = recoveryKey
            self.recoveryKeyLabel.text = recoveryKey
        }
    }
    
    private func render(error: Error) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.errorPresenter.presentError(from: self, forError: error, animated: true) {
            self.viewModel.process(viewAction: .errorAlertOk)
        }
    }
    
    private func updateDoneButton() {
        self.doneButton.isEnabled = self.hasSavedRecoveryKey
    }
    
    private func presentKeepSafeAlert() {
        let alertController = UIAlertController(title: VectorL10n.secretsSetupRecoveryKeyStorageAlertTitle,
                                                message: VectorL10n.secretsSetupRecoveryKeyStorageAlertMessage,
                                                preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: VectorL10n.continue, style: .cancel, handler: { action in
            self.viewModel.process(viewAction: .done)
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func shareRecoveryKey() {
        guard let recoveryKey = self.recoveryKey else {
            return
        }
        
        // Set up activity view controller
        let activityItems: [Any] = [ recoveryKey ]
        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        activityViewController.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
            
            // Enable made copy button only if user has selected an activity item and has setup recovery key without passphrase
            if completed {
                self.hasSavedRecoveryKey = true
                self.updateDoneButton()
            }
        }
        
        // Configure source view when activity view controller is presented with a popover
        if let popoverPresentationController = activityViewController.popoverPresentationController {
            popoverPresentationController.sourceView = self.exportButton
            popoverPresentationController.sourceRect = self.exportButton.bounds
            popoverPresentationController.permittedArrowDirections = [.down, .up]
        }
        
        self.present(activityViewController, animated: true)
    }
    
    // MARK: - Actions

    @IBAction private func exportButtonAction(_ sender: Any) {
        self.shareRecoveryKey()
    }
    
    @IBAction private func doneButtonAction(_ sender: Any) {
        
        if self.isPassphraseOnly {
            self.viewModel.process(viewAction: .done)
        } else {
            self.presentKeepSafeAlert()
        }
    }

    private func cancelButtonAction() {
        self.viewModel.process(viewAction: .cancel)
    }
}

// MARK: - SecretsSetupRecoveryKeyViewModelViewDelegate
extension SecretsSetupRecoveryKeyViewController: SecretsSetupRecoveryKeyViewModelViewDelegate {

    func secretsSetupRecoveryKeyViewModel(_ viewModel: SecretsSetupRecoveryKeyViewModelType, didUpdateViewState viewSate: SecretsSetupRecoveryKeyViewState) {
        self.render(viewState: viewSate)
    }
}
