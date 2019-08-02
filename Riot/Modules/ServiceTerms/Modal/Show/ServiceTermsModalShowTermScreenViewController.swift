// File created from ScreenTemplate
// $ createScreen.sh Modal/Show ServiceTermsModalShowTermScreen
/*
 Copyright 2019 New Vector Ltd
 
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

final class ServiceTermsModalShowTermScreenViewController: UIViewController {
    
    // MARK: - Constants
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private weak var scrollView: UIScrollView!
    
    // MARK: Private

    private var viewModel: ServiceTermsModalShowTermScreenViewModelType!
    private var theme: Theme!
    private weak var alertController: UIAlertController?

    // MARK: - Setup
    
    class func instantiate(with viewModel: ServiceTermsModalShowTermScreenViewModelType) -> ServiceTermsModalShowTermScreenViewController {
        let viewController = StoryboardScene.ServiceTermsModalShowTermScreenViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.title = VectorL10n.serviceTermsModalTitle
        
        self.setupViews()
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        self.viewModel.viewDelegate = self

        self.viewModel.process(viewAction: .load)
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
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        self.scrollView.keyboardDismissMode = .interactive
    }

    private func render(viewState: ServiceTermsModalShowTermScreenViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .loaded(let policy):
            self.renderLoaded(policy: policy)
        }
    }


    private func renderLoading() {
    }

    private func renderLoaded(policy: MXLoginPolicyData) {

        // All the UI is based on a single AlertController

        var title = VectorL10n.serviceTermsModalAlertTitle
        if self.viewModel.progress.totalUnitCount > 1 {
            title = VectorL10n.serviceTermsModalAlertTitleN(Int(self.viewModel.progress.completedUnitCount),
                                                            Int(self.viewModel.progress.totalUnitCount))
        }

        let message = VectorL10n.serviceTermsModalAlertMessageIm(policy.name)

        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: VectorL10n.serviceTermsModalAcceptButton, style: .default, handler: { action in
            self.viewModel.process(viewAction: .accept)
        }))

        alertController.addAction(UIAlertAction(title: VectorL10n.serviceTermsModalReviewButton, style: .default, handler: { action in
            self.reviewButtonAction()
        }))

        alertController.addAction(UIAlertAction(title: VectorL10n.serviceTermsModalDeclineButton, style: .destructive, handler: { action in
            self.viewModel.process(viewAction: .decline)
        }))


        self.present(alertController, animated: false, completion: nil)
        self.alertController = alertController
    }
    
    // MARK: - Actions

    private func reviewButtonAction() {

        // The alert is automatically dismissed when the user pressed the button
        // Reload the page to keep our AlertController-based UI still displayed
        self.viewModel.process(viewAction: .load)

        // Use the external web browser for displaying the doc
        guard let url = URL(string: self.viewModel.policy.url) else {
            print("[ServiceTermsModalShowTermScreenViewController] reviewButtonAction: Error: Cannot open policy url: \(self.viewModel.policy.url)")
            return
        }
        UIApplication.shared.open(url, options: [:])
    }

}


// MARK: - ServiceTermsModalShowTermScreenViewModelViewDelegate
extension ServiceTermsModalShowTermScreenViewController: ServiceTermsModalShowTermScreenViewModelViewDelegate {

    func serviceTermsModalShowTermScreenViewModel(_ viewModel: ServiceTermsModalShowTermScreenViewModelType, didUpdateViewState viewSate: ServiceTermsModalShowTermScreenViewState) {
        self.render(viewState: viewSate)
    }
}
