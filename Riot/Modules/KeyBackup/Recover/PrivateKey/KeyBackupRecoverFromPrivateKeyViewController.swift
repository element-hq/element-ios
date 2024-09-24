// File created from ScreenTemplate
// $ createScreen.sh .KeyBackup/Recover/PrivateKey KeyBackupRecoverFromPrivateKey
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import UIKit

final class KeyBackupRecoverFromPrivateKeyViewController: UIViewController {
    
    // MARK: - Constants
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private weak var shieldImageView: UIImageView!
    
    @IBOutlet private weak var informationLabel: UILabel!
    @IBOutlet private weak var progressLabel: UILabel!
    
    // MARK: Private

    private var viewModel: KeyBackupRecoverFromPrivateKeyViewModelType!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!

    // MARK: - Setup
    
    class func instantiate(with viewModel: KeyBackupRecoverFromPrivateKeyViewModelType) -> KeyBackupRecoverFromPrivateKeyViewController {
        let viewController = StoryboardScene.KeyBackupRecoverFromPrivateKeyViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.title = VectorL10n.keyBackupRecoverTitle
        
        self.setupViews()
        self.activityPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = MXKErrorAlertPresentation()
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        self.viewModel.viewDelegate = self

        self.viewModel.process(viewAction: .recover)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    
    // MARK: - Private
    
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
        
        let shieldImage = Asset.Images.keyBackupLogo.image.withRenderingMode(.alwaysTemplate)
        self.shieldImageView.image = shieldImage
        
        self.informationLabel.text = VectorL10n.keyBackupRecoverFromPrivateKeyInfo
    }
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        self.shieldImageView.tintColor = theme.textPrimaryColor
        
        self.informationLabel.textColor = theme.textPrimaryColor
    }

    private func render(viewState: KeyBackupRecoverFromPrivateKeyViewState) {
        switch viewState {
        case .loading(let progress):
            self.renderLoading(progress: progress)
        case .loaded:
            self.renderLoaded()
        case .error(let error):
            self.render(error: error)
        }
    }
    
    private func renderLoading(progress: Double) {
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
        
        let percent = Int(round(progress * 100))
        self.progressLabel.text = VectorL10n.keyBackupRecoverFromPrivateKeyProgress("\(percent)")
    }
    
    private func renderLoaded() {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
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


// MARK: - KeyBackupRecoverFromPrivateKeyViewModelViewDelegate
extension KeyBackupRecoverFromPrivateKeyViewController: KeyBackupRecoverFromPrivateKeyViewModelViewDelegate {

    func keyBackupRecoverFromPrivateKeyViewModel(_ viewModel: KeyBackupRecoverFromPrivateKeyViewModelType, didUpdateViewState viewSate: KeyBackupRecoverFromPrivateKeyViewState) {
        self.render(viewState: viewSate)
    }
}
