// File created from ScreenTemplate
// $ createScreen.sh Modal/Show ServiceTermsModalScreen
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

final class ServiceTermsModalScreenViewController: UIViewController {
    
    // MARK: - Constants
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var messageLabel: UILabel!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var acceptButton: UIButton!
    
    // MARK: Private

    private var viewModel: ServiceTermsModalScreenViewModelType!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!

    private var policies: [MXLoginPolicyData] = []

    /// Policies checked by the end user
    private var checkedPolicies: Set<Int> = []

    // MARK: - Setup
    
    class func instantiate(with viewModel: ServiceTermsModalScreenViewModelType) -> ServiceTermsModalScreenViewController {
        let viewController = StoryboardScene.ServiceTermsModalScreenViewController.initialScene.instantiate()
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
        self.activityPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = MXKErrorAlertPresentation()
        
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

        self.messageLabel.textColor = theme.textPrimaryColor

        self.acceptButton.backgroundColor = theme.backgroundColor
        theme.applyStyle(onButton: self.acceptButton)
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

        self.setupTableView()
        self.scrollView.keyboardDismissMode = .interactive
        
        self.messageLabel.text = VectorL10n.serviceTermsModalMessage

        self.acceptButton.setTitle(VectorL10n.serviceTermsModalAcceptButton, for: .normal)
        self.acceptButton.setTitle(VectorL10n.serviceTermsModalAcceptButton, for: .highlighted)
        self.refreshAcceptButton()
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(TableViewCellWithCheckBoxAndLabel.nib(), forCellReuseIdentifier: TableViewCellWithCheckBoxAndLabel.defaultReuseIdentifier())
    }

    private func render(viewState: ServiceTermsModalScreenViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .loaded(let policies):
            self.renderLoaded(policies: policies)
        case .accepted:
            self.renderAccepted()
        case .error(let error):
            self.render(error: error)
        }
    }

    private func renderLoading() {
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
    }

    private func renderLoaded(policies: [MXLoginPolicyData]) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)

        self.policies = policies
        self.refreshViews()
    }

    private func renderAccepting() {
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
    }

    private func renderAccepted() {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
    }
    
    private func render(error: Error) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }

    private func refreshViews() {
        self.tableView.reloadData()
        self.refreshAcceptButton()
    }

    private func refreshAcceptButton() {
        // Enable the button only if the user has accepted all policies
        self.acceptButton.isEnabled = (self.policies.count == self.checkedPolicies.count)
    }

    
    // MARK: - Actions

    @IBAction private func acceptButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .accept)
    }

    private func cancelButtonAction() {
        self.viewModel.process(viewAction: .cancel)
    }

    @objc private func didTapCheckbox(sender: UITapGestureRecognizer) {

        guard let policyIndex = sender.view?.tag else {
            return
        }

        if self.checkedPolicies.contains(policyIndex) {
            self.checkedPolicies.remove(policyIndex)
        } else {
            checkedPolicies.insert(policyIndex)
        }

        self.refreshViews()
    }
}


// MARK: - ServiceTermsModalScreenViewModelViewDelegate
extension ServiceTermsModalScreenViewController: ServiceTermsModalScreenViewModelViewDelegate {

    func ServiceTermsModalScreenViewModel(_ viewModel: ServiceTermsModalScreenViewModelType, didUpdateViewState viewSate: ServiceTermsModalScreenViewState) {
        self.render(viewState: viewSate)
    }
}

// MARK: - UITableViewDataSource

extension ServiceTermsModalScreenViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.policies.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellWithCheckBoxAndLabel.defaultReuseIdentifier(), for: indexPath) as? TableViewCellWithCheckBoxAndLabel else {
            fatalError("\(String(describing: TableViewCellWithCheckBoxAndLabel.self)) should be registered")
        }

        let policy = policies[indexPath.row]
        let checked = checkedPolicies.contains(indexPath.row)

        cell.label.text = policy.name
        cell.isEnabled = checked
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = UIColor.clear

        if let checkBox = cell.checkBox, checkBox.gestureRecognizers?.isEmpty ?? true {
            let gesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapCheckbox))
            gesture.numberOfTapsRequired = 1
            gesture.numberOfTouchesRequired = 1

            checkBox.isUserInteractionEnabled = true
            checkBox.tag = indexPath.row
            checkBox.addGestureRecognizer(gesture)
        }

        return cell
    }
}

extension ServiceTermsModalScreenViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let policy = policies[indexPath.row]
        self.viewModel.process(viewAction: .review(policy.url))
    }
}
