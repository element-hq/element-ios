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

    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var informationLabel: UILabel!
    
    @IBOutlet private weak var deviceNameTitleLabel: UILabel!
    @IBOutlet private weak var deviceNameLabel: UILabel!
    
    @IBOutlet private weak var deviceIdTitleLabel: UILabel!
    @IBOutlet private weak var deviceIdLabel: UILabel!
    
    @IBOutlet private weak var deviceKeyTitleLabel: UILabel!
    @IBOutlet private weak var deviceKeyLabel: UILabel!
    
    @IBOutlet private weak var additionalInformationLabel: UILabel!
    
    @IBOutlet private weak var verifyButton: RoundedButton!
    @IBOutlet private weak var cancelButton: RoundedButton!
    
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
        
        if let navigationController = self.navigationController {
            if navigationController.navigationBar.isHidden == true {
                self.navigationItem.hidesBackButton = true
                // Show navigation bar if needed
                navigationController.setNavigationBarHidden(false, animated: animated)
            } else {
                // Hide back button
                self.navigationItem.setHidesBackButton(true, animated: animated)
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Fix label height after orientation change. See here https://www.objc.io/issues/3-views/advanced-auto-layout-toolbox/#intrinsic-content-size-of-multi-line-text for more information.
        self.informationLabel.vc_fixMultilineHeight()
        self.deviceNameTitleLabel.vc_fixMultilineHeight()
        self.deviceNameLabel.vc_fixMultilineHeight()
        self.deviceIdLabel.vc_fixMultilineHeight()
        self.deviceIdTitleLabel.vc_fixMultilineHeight()
        self.deviceKeyTitleLabel.vc_fixMultilineHeight()
        self.deviceKeyLabel.vc_fixMultilineHeight()
        self.additionalInformationLabel.vc_fixMultilineHeight()
        
        self.view.layoutIfNeeded()
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

        self.informationLabel.textColor = theme.textPrimaryColor
        
        self.deviceNameTitleLabel.textColor = theme.textPrimaryColor
        self.deviceNameLabel.textColor = theme.textPrimaryColor
        
        self.deviceIdTitleLabel.textColor = theme.textPrimaryColor
        self.deviceIdLabel.textColor = theme.textPrimaryColor
        
        self.deviceKeyTitleLabel.textColor = theme.textPrimaryColor
        self.deviceKeyLabel.textColor = theme.textPrimaryColor
        
        self.additionalInformationLabel.textColor = theme.textPrimaryColor
        
        self.cancelButton.update(theme: theme)
        self.verifyButton.update(theme: theme)
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
        
        self.title = VectorL10n.keyVerificationManuallyVerifyDeviceTitle
        self.informationLabel.text = VectorL10n.keyVerificationManuallyVerifyDeviceInstruction
        self.deviceNameTitleLabel.text = VectorL10n.keyVerificationManuallyVerifyDeviceNameTitle
        self.deviceIdTitleLabel.text = VectorL10n.keyVerificationManuallyVerifyDeviceIdTitle
        self.deviceKeyTitleLabel.text = VectorL10n.keyVerificationManuallyVerifyDeviceKeyTitle
        self.additionalInformationLabel.text = VectorL10n.keyVerificationManuallyVerifyDeviceAdditionalInformation
        
        self.deviceNameLabel.text = nil
        self.deviceIdLabel.text = nil
        self.deviceKeyLabel.text = nil
        
        self.cancelButton.actionStyle = .cancel
    }

    private func render(viewState: KeyVerificationManuallyVerifyViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .loaded(let viewData):
            self.renderLoaded(viewData: viewData)
        case .error(let error):
            self.render(error: error)
        }
    }
    
    private func renderLoading() {
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
    }
    
    private func renderLoaded(viewData: KeyVerificationManuallyVerifyViewData) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        
        self.deviceNameLabel.text = viewData.deviceName
        self.deviceIdLabel.text = viewData.deviceId
        self.deviceKeyLabel.text = viewData.deviceKey
    }
    
    private func render(error: Error) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }
    
    // MARK: - Actions

    @IBAction private func verifyButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .verify)
    }
    
    @IBAction private func cancelButtonAction(_ sender: Any) {
        self.cancelAction()
    }

    private func cancelAction() {
        self.viewModel.process(viewAction: .cancel)
    }
}


// MARK: - KeyVerificationManuallyVerifyViewModelViewDelegate
extension KeyVerificationManuallyVerifyViewController: KeyVerificationManuallyVerifyViewModelViewDelegate {

    func keyVerificationManuallyVerifyViewModel(_ viewModel: KeyVerificationManuallyVerifyViewModelType, didUpdateViewState viewSate: KeyVerificationManuallyVerifyViewState) {
        self.render(viewState: viewSate)
    }
}
