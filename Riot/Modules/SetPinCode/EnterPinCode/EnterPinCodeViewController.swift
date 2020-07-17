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
    
    @IBOutlet private weak var placeholderStackView: UIStackView!
    @IBOutlet private weak var digitsStackView: UIStackView!
    @IBOutlet private weak var informationLabel: UILabel!
    
    // MARK: Private

    private var viewModel: EnterPinCodeViewModelType!
    private var theme: Theme!
    private var keyboardAvoider: KeyboardAvoider?
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
//        self.keyboardAvoider = KeyboardAvoider(scrollViewContainerView: self.view, scrollView: self.scrollView)
        self.activityPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = MXKErrorAlertPresentation()
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        self.viewModel.viewDelegate = self

//        self.viewModel.process(viewAction: .loadData)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.keyboardAvoider?.startAvoiding()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.keyboardAvoider?.stopAvoiding()
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

        // TODO: Set view colors here
        self.informationLabel.textColor = theme.textPrimaryColor

        updateThemesOfAllButtons(in: digitsStackView, with: theme)
    }
    
    private func updateThemesOfAllButtons(in view: UIView, with theme: Theme) {
        if let button = view as? UIButton {
            theme.applyStyle(onButton: button)
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
        let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
            self?.cancelButtonAction()
        }
        
        self.navigationItem.rightBarButtonItem = cancelBarButtonItem
        
        self.title = ""
    }

    private func render(viewState: EnterPinCodeViewState) {
        switch viewState {
        case .enterFirstPin:
            self.renderEnterFirstPin()
        case .confirmPin:
            self.renderConfirmPin()
        case .pinsDontMatch(let error):
            self.render(error: error)
        }
    }
    
    private func renderEnterFirstPin() {
        self.informationLabel.text = "Choose a PIN for security"
    }
    
    private func renderConfirmPin() {
        self.informationLabel.text = "Confirm your PIN"
        
        //  reset placeholders
        renderPlaceholdersCount(0)
    }
    
    private func render(error: Error) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }
    
    private func renderPlaceholdersCount(_ count: Int) {
        UIView.animate(withDuration: 0.3) {
            for view in self.placeholderStackView.arrangedSubviews {
                guard let imageView = view as? UIImageView else { continue }
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
    
}
