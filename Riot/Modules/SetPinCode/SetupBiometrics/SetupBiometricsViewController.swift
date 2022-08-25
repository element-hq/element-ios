// File created from ScreenTemplate
// $ createScreen.sh SetPinCode/SetupBiometrics SetupBiometrics
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

final class SetupBiometricsViewController: UIViewController {
    // MARK: - Constants
    
    private enum Constants {
        static let aConstant = 666
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private var logoImageView: UIImageView!
    @IBOutlet private var itemsStackView: UIStackView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var biometricsIconImageView: UIImageView!
    @IBOutlet private var enableButton: UIButton!
    
    // MARK: Private

    private var viewModel: SetupBiometricsViewModelType!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!

    // MARK: - Setup
    
    class func instantiate(with viewModel: SetupBiometricsViewModelType) -> SetupBiometricsViewController {
        let viewController = StoryboardScene.SetupBiometricsViewController.initialScene.instantiate()
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
        
        if #available(iOS 13.0, *) {
            modalPresentationStyle = .fullScreen
            isModalInPresentation = true
        }

        viewModel.process(viewAction: .loadData)
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
        subtitleLabel.textColor = theme.textSecondaryColor

        enableButton.backgroundColor = theme.tintColor
        enableButton.tintColor = theme.baseTextPrimaryColor
        enableButton.setTitleColor(theme.baseTextPrimaryColor, for: .normal)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        title = ""
    }
    
    private func showSkipButton() {
        navigationItem.rightBarButtonItem = MXKBarButtonItem(title: VectorL10n.skip, style: .plain) { [weak self] in
            self?.skipCancelButtonAction()
        }
    }
    
    private func showCancelButton() {
        navigationItem.rightBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
            self?.skipCancelButtonAction()
        }
    }
    
    private func hideSkipCancelButton() {
        navigationItem.rightBarButtonItem = nil
    }

    private func render(viewState: SetupBiometricsViewState) {
        switch viewState {
        case .setupAfterLogin:
            renderSetupAfterLogin()
        case .setupFromSettings:
            renderSetupFromSettings()
        case .unlock:
            renderUnlock()
        case .confirmToDisable:
            renderConfirmToDisable()
        case .cantUnlocked:
            renderCantUnlocked()
        }
    }
    
    private func renderSetupAfterLogin() {
        showSkipButton()
        
        guard let biometricsName = viewModel.localizedBiometricsName() else { return }
        titleLabel.text = VectorL10n.biometricsSetupTitleX(biometricsName)
        subtitleLabel.text = VectorL10n.biometricsSetupSubtitle
        biometricsIconImageView.image = viewModel.biometricsIcon()
        enableButton.setTitle(VectorL10n.biometricsSetupEnableButtonTitleX(biometricsName), for: .normal)
    }
    
    private func renderSetupFromSettings() {
        showCancelButton()
        
        guard let biometricsName = viewModel.localizedBiometricsName() else { return }
        titleLabel.text = VectorL10n.biometricsSetupTitleX(biometricsName)
        subtitleLabel.text = VectorL10n.biometricsSetupSubtitle
        biometricsIconImageView.image = viewModel.biometricsIcon()
        enableButton.setTitle(VectorL10n.biometricsSetupEnableButtonTitleX(biometricsName), for: .normal)
    }
    
    private func renderUnlock() {
        hideSkipCancelButton()
        
        logoImageView.isHidden = false
        //  hide all items but the logo
        itemsStackView.isHidden = true
        
        viewModel.process(viewAction: .unlock)
    }
    
    private func renderConfirmToDisable() {
        showCancelButton()
        
        guard let biometricsName = viewModel.localizedBiometricsName() else { return }
        titleLabel.text = VectorL10n.biometricsDesetupTitleX(biometricsName)
        subtitleLabel.text = nil
        biometricsIconImageView.image = viewModel.biometricsIcon()
        enableButton.setTitle(VectorL10n.biometricsDesetupDisableButtonTitleX(biometricsName), for: .normal)
    }
    
    private func renderCantUnlocked() {
        guard let biometricsName = viewModel.localizedBiometricsName() else { return }
        
        let controller = UIAlertController(title: VectorL10n.biometricsCantUnlockedAlertTitle,
                                           message: VectorL10n.biometricsCantUnlockedAlertMessageX(biometricsName, biometricsName),
                                           preferredStyle: .alert)
        
        let resetAction = UIAlertAction(title: VectorL10n.biometricsCantUnlockedAlertMessageLogin, style: .default) { _ in
            self.viewModel.process(viewAction: .cantUnlockedAlertResetAction)
        }
        
        let retryAction = UIAlertAction(title: VectorL10n.biometricsCantUnlockedAlertMessageRetry, style: .cancel) { _ in
            self.viewModel.process(viewAction: .unlock)
        }
        
        controller.addAction(resetAction)
        controller.addAction(retryAction)
        present(controller, animated: true, completion: nil)
    }
    
    // MARK: - Actions

    @IBAction private func enableButtonAction(_ sender: Any) {
        viewModel.process(viewAction: .enableDisableTapped)
    }

    private func skipCancelButtonAction() {
        viewModel.process(viewAction: .skipOrCancel)
    }
}

// MARK: - SetupBiometricsViewModelViewDelegate

extension SetupBiometricsViewController: SetupBiometricsViewModelViewDelegate {
    func setupBiometricsViewModel(_ viewModel: SetupBiometricsViewModelType, didUpdateViewState viewSate: SetupBiometricsViewState) {
        render(viewState: viewSate)
    }
}
