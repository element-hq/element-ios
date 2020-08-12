// File created from ScreenTemplate
// $ createScreen.sh SetPinCode/EnterPinCode EnterPinCode
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

final class EnterPinCodeViewController: UIViewController {
    
    // MARK: - Constants
    
    private enum Constants {
        static let aConstant: Int = 666
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var logoImageView: UIImageView!
    @IBOutlet private weak var placeholderStackView: UIStackView!
    @IBOutlet private weak var digitsStackView: UIStackView!
    @IBOutlet private weak var informationLabel: UILabel!
    @IBOutlet private weak var forgotPinButton: UIButton!
    
    // MARK: Private

    private var viewModel: EnterPinCodeViewModelType!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!

    // MARK: - Setup
    
    class func instantiate(with viewModel: EnterPinCodeViewModelType) -> EnterPinCodeViewController {
        let viewController = StoryboardScene.EnterPinCodeViewController.initialScene.instantiate()
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
        
        //  force orientation to portrait if phone
        if UIDevice.current.isPhone {
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        //  limit orientation to portrait only for phone
        if UIDevice.current.isPhone {
            return .portrait
        }
        return super.supportedInterfaceOrientations
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        if UIDevice.current.isPhone {
            return .portrait
        }
        return super.preferredInterfaceOrientationForPresentation
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }

        self.informationLabel.textColor = theme.textPrimaryColor

        updateThemesOfAllImages(in: placeholderStackView, with: theme)
        updateThemesOfAllButtons(in: digitsStackView, with: theme)
        
        theme.applyStyle(onButton: forgotPinButton)
    }
    
    private func updateThemesOfAllImages(in view: UIView, with theme: Theme) {
        if let imageView = view as? UIImageView {
            imageView.tintColor = theme.noticeSecondaryColor
        } else {
            for subview in view.subviews {
                updateThemesOfAllImages(in: subview, with: theme)
            }
        }
    }
    
    private func updateThemesOfAllButtons(in view: UIView, with theme: Theme) {
        if let button = view as? UIButton {
            button.tintColor = theme.textPrimaryColor
            button.setTitleColor(theme.textPrimaryColor, for: .normal)
        } else {
            for subview in view.subviews {
                updateThemesOfAllButtons(in: subview, with: theme)
            }
        }
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        showCancelButton()
        
        self.title = ""
        
        placeholderStackView.vc_removeAllArrangedSubviews()
        for i in 0..<PinCodePreferences.shared.numberOfDigits {
            let imageView = UIImageView(image: Asset.Images.selectionUntick.image)
            imageView.heightAnchor.constraint(equalToConstant: 24).isActive = true
            imageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
            imageView.tag = i
            placeholderStackView.addArrangedSubview(imageView)
        }
    }
    
    private func showCancelButton() {
        let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
            self?.cancelButtonAction()
        }
        
        self.navigationItem.rightBarButtonItem = cancelBarButtonItem
    }
    
    private func hideCancelButton() {
        self.navigationItem.rightBarButtonItem = nil
    }
    
    private func render(viewState: EnterPinCodeViewState) {
        switch viewState {
        case .choosePin:
            self.renderChoosePin()
        case .confirmPin:
            self.renderConfirmPin()
        case .pinsDontMatch:
            self.renderPinsDontMatch()
        case .unlock:
            self.renderUnlockByPin()
        case .wrongPin:
            self.renderWrongPin()
        case .wrongPinTooManyTimes:
            self.renderWrongPinTooManyTimes()
        case .forgotPin:
            self.renderForgotPin()
        case .confirmPinToDisable:
            self.renderConfirmPinToDisable()
        }
    }
    
    private func renderChoosePin() {
        self.logoImageView.isHidden = true
        self.informationLabel.text = VectorL10n.pinProtectionChoosePin
        self.forgotPinButton.isHidden = true
    }
    
    private func renderConfirmPin() {
        self.informationLabel.text = VectorL10n.pinProtectionConfirmPin
        
        //  reset placeholders
        renderPlaceholdersCount(0)
    }
    
    private func renderPinsDontMatch() {
        let error = MXKErrorViewModel(title: VectorL10n.pinProtectionMismatchErrorTitle,
                                      message: VectorL10n.pinProtectionMismatchErrorMessage)
        
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.errorPresenter.presentError(from: self, for: error, animated: true) {
            self.viewModel.process(viewAction: .pinsDontMatchAlertAction)
        }
    }
    
    private func renderUnlockByPin() {
        hideCancelButton()
        self.logoImageView.isHidden = false
        self.informationLabel.text = VectorL10n.pinProtectionEnterPin
        self.forgotPinButton.isHidden = false
    }
    
    private func renderWrongPin() {
        self.placeholderStackView.vc_shake()
    }
    
    private func renderWrongPinTooManyTimes() {
        let error = MXKErrorViewModel(title: VectorL10n.pinProtectionMismatchErrorTitle,
                                      message: VectorL10n.pinProtectionMismatchTooManyTimesErrorMessage)
        
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.errorPresenter.presentError(from: self, for: error, animated: true, handler: nil)
    }
    
    private func renderForgotPin() {
        let controller = UIAlertController(title: VectorL10n.pinProtectionResetAlertTitle,
                                           message: VectorL10n.pinProtectionResetAlertMessage,
                                           preferredStyle: .alert)
        
        let resetAction = UIAlertAction(title: VectorL10n.pinProtectionResetAlertActionReset, style: .default) { (_) in
            self.viewModel.process(viewAction: .forgotPinAlertResetAction)
        }
        
        let cancelAction = UIAlertAction(title: VectorL10n.cancel, style: .cancel) { (_) in
            self.viewModel.process(viewAction: .forgotPinAlertCancelAction)
        }
        
        controller.addAction(resetAction)
        controller.addAction(cancelAction)
        self.present(controller, animated: true, completion: nil)
    }
    
    private func renderConfirmPinToDisable() {
        self.logoImageView.isHidden = true
        self.informationLabel.text = VectorL10n.pinProtectionConfirmPinToDisable
        self.forgotPinButton.isHidden = true
    }
    
    private func renderPlaceholdersCount(_ count: Int) {
        UIView.animate(withDuration: 0.3) {
            for case let imageView as UIImageView in self.placeholderStackView.arrangedSubviews {
                if imageView.tag < count {
                    imageView.image = Asset.Images.placeholder.image
                } else {
                    imageView.image = Asset.Images.selectionUntick.image
                }
            }
        }
    }

    // MARK: - Actions

    @IBAction private func digitButtonAction(_ sender: UIButton) {
        self.viewModel.process(viewAction: .digitPressed(sender.tag))
    }
    
    @IBAction private func forgotPinButtonAction(_ sender: UIButton) {
        self.viewModel.process(viewAction: .forgotPinPressed)
    }

    private func cancelButtonAction() {
        self.viewModel.process(viewAction: .cancel)
    }
}


// MARK: - EnterPinCodeViewModelViewDelegate
extension EnterPinCodeViewController: EnterPinCodeViewModelViewDelegate {

    func enterPinCodeViewModel(_ viewModel: EnterPinCodeViewModelType, didUpdateViewState viewSate: EnterPinCodeViewState) {
        self.render(viewState: viewSate)
    }
    
    func enterPinCodeViewModel(_ viewModel: EnterPinCodeViewModelType, didUpdatePlaceholdersCount count: Int) {
        self.renderPlaceholdersCount(count)
    }
    
    func enterPinCodeViewModel(_ viewModel: EnterPinCodeViewModelType, didUpdateCancelButtonHidden isHidden: Bool) {
        if isHidden {
            hideCancelButton()
        } else {
            showCancelButton()
        }
    }
    
}
