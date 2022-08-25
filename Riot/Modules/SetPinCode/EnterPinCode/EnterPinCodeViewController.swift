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
        static let aConstant = 666
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private var mainStackView: UIStackView!
    @IBOutlet private var inactiveView: UIView!
    @IBOutlet private var inactiveLogoImageView: UIImageView!
    @IBOutlet private var logoImageView: UIImageView!
    @IBOutlet private var placeholderStackView: UIStackView!
    @IBOutlet private var notAllowedPinView: UIView!
    @IBOutlet private var notAllowedPinLineView: UIView!
    @IBOutlet private var notAllowedPinLabel: UILabel!
    @IBOutlet private var digitsStackView: UIStackView!
    @IBOutlet private var informationLabel: UILabel!
    @IBOutlet private var explanatoryLabel: UILabel!
    @IBOutlet private var forgotPinButton: UIButton!
    @IBOutlet private var bottomView: UIView!
    
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
        
        setupViews()
        activityPresenter = ActivityIndicatorPresenter()
        errorPresenter = MXKErrorAlertPresentation()
        
        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
        
        viewModel.viewDelegate = self

        viewModel.process(viewAction: .loadData)
        
        //  force orientation to portrait if phone
        if UIDevice.current.isPhone {
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UIApplication.shared.vc_closeKeyboard()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        self.theme.statusBarStyle
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
        
        view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }

        informationLabel.textColor = theme.textPrimaryColor
        explanatoryLabel.textColor = theme.textSecondaryColor
        notAllowedPinLineView.backgroundColor = theme.noticeColor
        notAllowedPinLabel.textColor = theme.noticeColor

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
        update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
            self?.cancelButtonAction()
        }
        
        navigationItem.rightBarButtonItem = cancelBarButtonItem
        showCancelButton()
        
        title = ""
        
        notAllowedPinLabel.text = VectorL10n.pinProtectionNotAllowedPin
        
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
        navigationController?.navigationBar.isHidden = false
    }
    
    private func hideCancelButton() {
        navigationController?.navigationBar.isHidden = true
    }
    
    private func render(viewState: EnterPinCodeViewState) {
        switch viewState {
        case .choosePin:
            renderChoosePin()
        case .choosePinAfterLogin:
            renderChoosePinAfterLogin()
        case .choosePinAfterRegister:
            renderChoosePinAfterRegister()
        case .notAllowedPin:
            renderNotAllowedPin()
        case .confirmPin:
            renderConfirmPin()
        case .pinsDontMatch:
            renderPinsDontMatch()
        case .unlock:
            renderUnlockByPin()
        case .wrongPin:
            renderWrongPin()
        case .wrongPinTooManyTimes:
            renderWrongPinTooManyTimes()
        case .forgotPin:
            renderForgotPin()
        case .confirmPinToDisable:
            renderConfirmPinToDisable()
        case .inactive:
            renderInactive()
        case .changePin:
            renderChangePin()
        }
    }
    
    private func renderChoosePin() {
        inactiveView.isHidden = true
        mainStackView.isHidden = false
        logoImageView.isHidden = true
        informationLabel.text = VectorL10n.pinProtectionChoosePin
        explanatoryLabel.isHidden = false
        forgotPinButton.isHidden = true
        bottomView.isHidden = false
        notAllowedPinView.isHidden = true
    }
    
    private func renderChoosePinAfterLogin() {
        renderChoosePin()
        informationLabel.text = VectorL10n.pinProtectionChoosePinWelcomeAfterLogin + "\n" + VectorL10n.pinProtectionChoosePin
    }
    
    private func renderChoosePinAfterRegister() {
        renderChoosePin()
        informationLabel.text = VectorL10n.pinProtectionChoosePinWelcomeAfterRegister + "\n" + VectorL10n.pinProtectionChoosePin
    }
    
    private func renderNotAllowedPin() {
        inactiveView.isHidden = true
        mainStackView.isHidden = false
        logoImageView.isHidden = true
        forgotPinButton.isHidden = true
        bottomView.isHidden = false
        notAllowedPinView.isHidden = false
        
        renderPlaceholdersCount(.max, error: true)
    }
    
    private func renderConfirmPin() {
        inactiveView.isHidden = true
        mainStackView.isHidden = false
        informationLabel.text = VectorL10n.pinProtectionConfirmPin
        notAllowedPinView.isHidden = true
        
        //  reset placeholders
        renderPlaceholdersCount(0)
    }
    
    private func renderPinsDontMatch() {
        let error = MXKErrorViewModel(title: VectorL10n.pinProtectionMismatchErrorTitle,
                                      message: VectorL10n.pinProtectionMismatchErrorMessage)
        
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        errorPresenter.presentError(from: self, for: error, animated: true) {
            self.viewModel.process(viewAction: .pinsDontMatchAlertAction)
        }
    }
    
    private func renderUnlockByPin() {
        hideCancelButton()
        inactiveView.isHidden = true
        mainStackView.isHidden = false
        logoImageView.isHidden = false
        informationLabel.text = VectorL10n.pinProtectionEnterPin
        explanatoryLabel.isHidden = true
        forgotPinButton.isHidden = false
        bottomView.isHidden = true
        notAllowedPinView.isHidden = true
    }
    
    private func renderWrongPin() {
        inactiveView.isHidden = true
        mainStackView.isHidden = false
        notAllowedPinView.isHidden = true
        explanatoryLabel.isHidden = true
        placeholderStackView.vc_shake()
    }
    
    private func renderWrongPinTooManyTimes() {
        let error = MXKErrorViewModel(title: VectorL10n.pinProtectionMismatchErrorTitle,
                                      message: VectorL10n.pinProtectionMismatchTooManyTimesErrorMessage)
        
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        errorPresenter.presentError(from: self, for: error, animated: true, handler: nil)
    }
    
    private func renderForgotPin() {
        let controller = UIAlertController(title: VectorL10n.pinProtectionResetAlertTitle,
                                           message: VectorL10n.pinProtectionResetAlertMessage,
                                           preferredStyle: .alert)
        
        let resetAction = UIAlertAction(title: VectorL10n.pinProtectionResetAlertActionReset, style: .default) { _ in
            self.viewModel.process(viewAction: .forgotPinAlertResetAction)
        }
        
        let cancelAction = UIAlertAction(title: VectorL10n.cancel, style: .cancel) { _ in
            self.viewModel.process(viewAction: .forgotPinAlertCancelAction)
        }
        
        controller.addAction(resetAction)
        controller.addAction(cancelAction)
        present(controller, animated: true, completion: nil)
    }
    
    private func renderConfirmPinToDisable() {
        inactiveView.isHidden = true
        mainStackView.isHidden = false
        logoImageView.isHidden = true
        informationLabel.text = VectorL10n.pinProtectionConfirmPinToDisable
        explanatoryLabel.isHidden = true
        forgotPinButton.isHidden = true
        bottomView.isHidden = false
        notAllowedPinView.isHidden = true
    }
    
    private func renderInactive() {
        hideCancelButton()
        inactiveView.isHidden = false
        mainStackView.isHidden = true
        notAllowedPinView.isHidden = true
        explanatoryLabel.isHidden = true
    }
    
    private func renderChangePin() {
        inactiveView.isHidden = true
        mainStackView.isHidden = false
        logoImageView.isHidden = true
        informationLabel.text = VectorL10n.pinProtectionConfirmPinToChange
        explanatoryLabel.isHidden = true
        forgotPinButton.isHidden = true
        bottomView.isHidden = false
        notAllowedPinView.isHidden = true
    }
    
    private func renderPlaceholdersCount(_ count: Int, error: Bool = false) {
        UIView.animate(withDuration: 0.3) {
            for case let imageView as UIImageView in self.placeholderStackView.arrangedSubviews {
                if imageView.tag < count {
                    if error {
                        imageView.image = Asset.Images.placeholder.image.vc_tintedImage(usingColor: self.theme.noticeColor)
                    } else {
                        imageView.image = Asset.Images.placeholder.image
                    }
                } else {
                    imageView.image = Asset.Images.selectionUntick.image
                }
            }
        }
    }

    // MARK: - Actions

    @IBAction private func digitButtonAction(_ sender: UIButton) {
        viewModel.process(viewAction: .digitPressed(sender.tag))
    }
    
    @IBAction private func forgotPinButtonAction(_ sender: UIButton) {
        viewModel.process(viewAction: .forgotPinPressed)
    }

    private func cancelButtonAction() {
        viewModel.process(viewAction: .cancel)
    }
}

// MARK: - EnterPinCodeViewModelViewDelegate

extension EnterPinCodeViewController: EnterPinCodeViewModelViewDelegate {
    func enterPinCodeViewModel(_ viewModel: EnterPinCodeViewModelType, didUpdateViewState viewSate: EnterPinCodeViewState) {
        render(viewState: viewSate)
    }
    
    func enterPinCodeViewModel(_ viewModel: EnterPinCodeViewModelType, didUpdatePlaceholdersCount count: Int) {
        renderPlaceholdersCount(count)
    }
    
    func enterPinCodeViewModel(_ viewModel: EnterPinCodeViewModelType, didUpdateCancelButtonHidden isHidden: Bool) {
        if isHidden {
            hideCancelButton()
        } else {
            showCancelButton()
        }
    }
}
