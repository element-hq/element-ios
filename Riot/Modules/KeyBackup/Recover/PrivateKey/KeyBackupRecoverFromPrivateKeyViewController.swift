// File created from ScreenTemplate
// $ createScreen.sh .KeyBackup/Recover/PrivateKey KeyBackupRecoverFromPrivateKey
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

final class KeyBackupRecoverFromPrivateKeyViewController: UIViewController {
    // MARK: - Constants
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private var shieldImageView: UIImageView!
    
    @IBOutlet private var informationLabel: UILabel!
    
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
        
        title = VectorL10n.keyBackupRecoverTitle
        
        setupViews()
        activityPresenter = ActivityIndicatorPresenter()
        errorPresenter = MXKErrorAlertPresentation()
        
        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
        
        viewModel.viewDelegate = self

        viewModel.process(viewAction: .recover)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        theme.statusBarStyle
    }
    
    // MARK: - Private
    
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
        
        let shieldImage = Asset.Images.keyBackupLogo.image.withRenderingMode(.alwaysTemplate)
        shieldImageView.image = shieldImage
        
        informationLabel.text = VectorL10n.keyBackupRecoverFromPrivateKeyInfo
    }
    
    private func update(theme: Theme) {
        self.theme = theme
        
        view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        shieldImageView.tintColor = theme.textPrimaryColor
        
        informationLabel.textColor = theme.textPrimaryColor
    }

    private func render(viewState: KeyBackupRecoverFromPrivateKeyViewState) {
        switch viewState {
        case .loading:
            renderLoading()
        case .loaded:
            renderLoaded()
        case .error(let error):
            render(error: error)
        }
    }
    
    private func renderLoading() {
        activityPresenter.presentActivityIndicator(on: view, animated: true)
    }
    
    private func renderLoaded() {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
    }
    
    private func render(error: Error) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }

    // MARK: - Actions

    private func cancelButtonAction() {
        viewModel.process(viewAction: .cancel)
    }
}

// MARK: - KeyBackupRecoverFromPrivateKeyViewModelViewDelegate

extension KeyBackupRecoverFromPrivateKeyViewController: KeyBackupRecoverFromPrivateKeyViewModelViewDelegate {
    func keyBackupRecoverFromPrivateKeyViewModel(_ viewModel: KeyBackupRecoverFromPrivateKeyViewModelType, didUpdateViewState viewSate: KeyBackupRecoverFromPrivateKeyViewState) {
        render(viewState: viewSate)
    }
}
