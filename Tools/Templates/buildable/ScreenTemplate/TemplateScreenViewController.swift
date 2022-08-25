/*
 Copyright 2021 New Vector Ltd
 
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

final class TemplateScreenViewController: UIViewController {
    // MARK: - Constants
    
    private enum Constants {
        static let aConstant = 666
    }
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private var scrollView: UIScrollView!
    
    @IBOutlet private var informationLabel: UILabel!
    @IBOutlet private var doneButton: UIButton!
    
    // MARK: Private

    private var viewModel: TemplateScreenViewModelProtocol!
    private var theme: Theme!
    private var keyboardAvoider: KeyboardAvoider?
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!

    // MARK: - Setup
    
    class func instantiate(with viewModel: TemplateScreenViewModelProtocol) -> TemplateScreenViewController {
        let viewController = StoryboardScene.TemplateScreenViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        setupViews()
        keyboardAvoider = KeyboardAvoider(scrollViewContainerView: view, scrollView: scrollView)
        activityPresenter = ActivityIndicatorPresenter()
        errorPresenter = MXKErrorAlertPresentation()
        
        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
        
        viewModel.viewDelegate = self

        viewModel.process(viewAction: .loadData)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        keyboardAvoider?.startAvoiding()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        keyboardAvoider?.stopAvoiding()
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

        // TODO: Set view colors here
        informationLabel.textColor = theme.textPrimaryColor

        doneButton.backgroundColor = theme.backgroundColor
        theme.applyStyle(onButton: doneButton)
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
        
        title = "Template"
        
        scrollView.keyboardDismissMode = .interactive
        
        informationLabel.text = "VectorL10n.templateScreenTitle"
    }

    private func render(viewState: TemplateScreenViewState) {
        switch viewState {
        case .idle:
            break
        case .loading:
            renderLoading()
        case .loaded(let displayName):
            renderLoaded(displayName: displayName)
        case .error(let error):
            render(error: error)
        }
    }
    
    private func renderLoading() {
        activityPresenter.presentActivityIndicator(on: view, animated: true)
        informationLabel.text = "Fetch display name"
    }
    
    private func renderLoaded(displayName: String) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)

        informationLabel.text = "You display name: \(displayName)"
    }
    
    private func render(error: Error) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }

    // MARK: - Actions

    @IBAction private func doneButtonAction(_ sender: Any) {
        viewModel.process(viewAction: .complete)
    }

    private func cancelButtonAction() {
        viewModel.process(viewAction: .cancel)
    }
}

// MARK: - TemplateScreenViewModelViewDelegate

extension TemplateScreenViewController: TemplateScreenViewModelViewDelegate {
    func templateScreenViewModel(_ viewModel: TemplateScreenViewModelProtocol, didUpdateViewState viewSate: TemplateScreenViewState) {
        render(viewState: viewSate)
    }
}
