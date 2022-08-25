// File created from ScreenTemplate
// $ createScreen.sh KeyVerification/Device/ManuallyVerify KeyVerificationManuallyVerify
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

final class KeyVerificationManuallyVerifyViewController: UIViewController {
    // MARK: - Constants
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private var scrollView: UIScrollView!
    
    @IBOutlet private var informationLabel: UILabel!
    
    @IBOutlet private var deviceNameTitleLabel: UILabel!
    @IBOutlet private var deviceNameLabel: UILabel!
    
    @IBOutlet private var deviceIdTitleLabel: UILabel!
    @IBOutlet private var deviceIdLabel: UILabel!
    
    @IBOutlet private var deviceKeyTitleLabel: UILabel!
    @IBOutlet private var deviceKeyLabel: UILabel!
    
    @IBOutlet private var additionalInformationLabel: UILabel!
    
    @IBOutlet private var verifyButton: RoundedButton!
    @IBOutlet private var cancelButton: RoundedButton!
    
    // MARK: Private

    private var viewModel: KeyVerificationManuallyVerifyViewModelType!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!

    // MARK: - Setup
    
    class func instantiate(with viewModel: KeyVerificationManuallyVerifyViewModelType) -> KeyVerificationManuallyVerifyViewController {
        let viewController = StoryboardScene.KeyVerificationManuallyVerifyViewController.initialScene.instantiate()
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
        
        if let navigationController = navigationController {
            if navigationController.navigationBar.isHidden == true {
                navigationItem.hidesBackButton = true
                // Show navigation bar if needed
                navigationController.setNavigationBarHidden(false, animated: animated)
            } else {
                // Hide back button
                navigationItem.setHidesBackButton(true, animated: animated)
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Fix label height after orientation change. See here https://www.objc.io/issues/3-views/advanced-auto-layout-toolbox/#intrinsic-content-size-of-multi-line-text for more information.
        informationLabel.vc_fixMultilineHeight()
        deviceNameTitleLabel.vc_fixMultilineHeight()
        deviceNameLabel.vc_fixMultilineHeight()
        deviceIdLabel.vc_fixMultilineHeight()
        deviceIdTitleLabel.vc_fixMultilineHeight()
        deviceKeyTitleLabel.vc_fixMultilineHeight()
        deviceKeyLabel.vc_fixMultilineHeight()
        additionalInformationLabel.vc_fixMultilineHeight()
        
        view.layoutIfNeeded()
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

        informationLabel.textColor = theme.textPrimaryColor
        
        deviceNameTitleLabel.textColor = theme.textPrimaryColor
        deviceNameLabel.textColor = theme.textPrimaryColor
        
        deviceIdTitleLabel.textColor = theme.textPrimaryColor
        deviceIdLabel.textColor = theme.textPrimaryColor
        
        deviceKeyTitleLabel.textColor = theme.textPrimaryColor
        deviceKeyLabel.textColor = theme.textPrimaryColor
        
        additionalInformationLabel.textColor = theme.textPrimaryColor
        
        cancelButton.update(theme: theme)
        verifyButton.update(theme: theme)
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
        
        title = VectorL10n.keyVerificationManuallyVerifyDeviceTitle
        informationLabel.text = VectorL10n.keyVerificationManuallyVerifyDeviceInstruction
        deviceNameTitleLabel.text = VectorL10n.keyVerificationManuallyVerifyDeviceNameTitle
        deviceIdTitleLabel.text = VectorL10n.keyVerificationManuallyVerifyDeviceIdTitle
        deviceKeyTitleLabel.text = VectorL10n.keyVerificationManuallyVerifyDeviceKeyTitle
        additionalInformationLabel.text = VectorL10n.keyVerificationManuallyVerifyDeviceAdditionalInformation
        
        deviceNameLabel.text = nil
        deviceIdLabel.text = nil
        deviceKeyLabel.text = nil
        
        cancelButton.actionStyle = .cancel
    }

    private func render(viewState: KeyVerificationManuallyVerifyViewState) {
        switch viewState {
        case .loading:
            renderLoading()
        case .loaded(let viewData):
            renderLoaded(viewData: viewData)
        case .error(let error):
            render(error: error)
        }
    }
    
    private func renderLoading() {
        activityPresenter.presentActivityIndicator(on: view, animated: true)
    }
    
    private func renderLoaded(viewData: KeyVerificationManuallyVerifyViewData) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        
        deviceNameLabel.text = viewData.deviceName
        deviceIdLabel.text = viewData.deviceId
        deviceKeyLabel.text = viewData.deviceKey
    }
    
    private func render(error: Error) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }
    
    // MARK: - Actions

    @IBAction private func verifyButtonAction(_ sender: Any) {
        viewModel.process(viewAction: .verify)
    }
    
    @IBAction private func cancelButtonAction(_ sender: Any) {
        cancelAction()
    }

    private func cancelAction() {
        viewModel.process(viewAction: .cancel)
    }
}

// MARK: - KeyVerificationManuallyVerifyViewModelViewDelegate

extension KeyVerificationManuallyVerifyViewController: KeyVerificationManuallyVerifyViewModelViewDelegate {
    func keyVerificationManuallyVerifyViewModel(_ viewModel: KeyVerificationManuallyVerifyViewModelType, didUpdateViewState viewSate: KeyVerificationManuallyVerifyViewState) {
        render(viewState: viewSate)
    }
}
