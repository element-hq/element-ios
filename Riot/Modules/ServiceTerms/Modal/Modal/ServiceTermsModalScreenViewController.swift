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
    
    private enum Constants {
        /// Reuse identifier for the prototype cell in the storyboard.
        static let cellReuseIdentifier = "Service Terms Cell"
        static let minimumTableViewHeight: CGFloat = 120
    }
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private var scrollView: UIScrollView!
    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var descriptionLabel: UILabel!
    @IBOutlet private var footerLabel: UILabel!
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var acceptButton: UIButton!
    @IBOutlet private var declineButton: UIButton!
    @IBOutlet private var tableViewHeightConstraint: NSLayoutConstraint!
    
    // MARK: Private

    private var viewModel: ServiceTermsModalScreenViewModelType!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!

    private var policies: [MXLoginPolicyData] = []
    
    private var tableHeaderView: ServiceTermsModalTableHeaderView!

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

        setupViews()
        activityPresenter = ActivityIndicatorPresenter()
        errorPresenter = MXKErrorAlertPresentation()
        
        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
        
        viewModel.viewDelegate = self

        viewModel.process(viewAction: .load)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        tableViewHeightConstraint.constant = max(Constants.minimumTableViewHeight, tableView.contentSize.height)
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

        titleLabel.font = theme.fonts.bodySB
        titleLabel.textColor = theme.colors.primaryContent
        
        descriptionLabel.font = theme.fonts.body
        descriptionLabel.textColor = theme.colors.secondaryContent
        
        tableHeaderView.update(theme: theme)
        
        footerLabel.font = theme.fonts.footnote.withSize(13)
        footerLabel.textColor = theme.colors.secondaryContent

        acceptButton.titleLabel?.font = theme.fonts.body
        acceptButton.setTitleColor(theme.colors.background, for: .normal)
        acceptButton.backgroundColor = theme.colors.accent

        theme.applyStyle(onButton: declineButton)
        declineButton.titleLabel?.font = theme.fonts.body
        declineButton.setTitleColor(theme.warningColor, for: .normal)

        refreshViews()
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        setupTableView()
        scrollView.keyboardDismissMode = .interactive
        
        titleLabel.text = VectorL10n.serviceTermsModalTitleMessage
        footerLabel.text = VectorL10n.serviceTermsModalFooter
        
        tableHeaderView.serviceURLLabel.text = viewModel.serviceUrl

        acceptButton.setTitle(VectorL10n.serviceTermsModalAcceptButton, for: .normal)
        acceptButton.setTitle(VectorL10n.serviceTermsModalAcceptButton, for: .highlighted)
        acceptButton.layer.cornerRadius = 8

        declineButton.setTitle(VectorL10n.serviceTermsModalDeclineButton, for: .normal)
        declineButton.setTitle(VectorL10n.serviceTermsModalDeclineButton, for: .highlighted)
        
        if viewModel.serviceType == MXServiceTypeIdentityService {
            descriptionLabel.text = VectorL10n.serviceTermsModalDescriptionIdentityServer
            tableHeaderView.titleLabel.text = VectorL10n.serviceTermsModalTableHeaderIdentityServer
            imageView.image = Asset.Images.findYourContactsFacepile.image
        } else {
            descriptionLabel.text = VectorL10n.serviceTermsModalDescriptionIntegrationManager
            tableHeaderView.titleLabel.text = VectorL10n.serviceTermsModalTableHeaderIntegrationManager
            imageView.image = Asset.Images.integrationManagerIconpile.image
        }
    }

    private func setupTableView() {
        guard let tableView = tableView else { return }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.alwaysBounceVertical = false
        tableView.backgroundColor = .clear
        tableView.register(TableViewCellWithCheckBoxAndLabel.nib(), forCellReuseIdentifier: TableViewCellWithCheckBoxAndLabel.defaultReuseIdentifier())
        
        tableHeaderView = ServiceTermsModalTableHeaderView.instantiate()
        tableHeaderView.delegate = self
        tableView.tableHeaderView = tableHeaderView
        
        tableView.addConstraint(NSLayoutConstraint(item: tableView,
                                                   attribute: .width,
                                                   relatedBy: .equal,
                                                   toItem: tableHeaderView,
                                                   attribute: .width,
                                                   multiplier: 1,
                                                   constant: 10))
    }

    private func render(viewState: ServiceTermsModalScreenViewState) {
        switch viewState {
        case .loading:
            renderLoading()
        case .loaded(let policies, let alreadyAcceptedPoliciesUrls):
            renderLoaded(policies: policies, alreadyAcceptedPoliciesUrls: alreadyAcceptedPoliciesUrls)
        case .accepted:
            renderAccepted()
        case .error(let error):
            render(error: error)
        }
    }

    private func renderLoading() {
        activityPresenter.presentActivityIndicator(on: view, animated: true)
        acceptButton.isEnabled = false
    }

    private func renderLoaded(policies: [MXLoginPolicyData], alreadyAcceptedPoliciesUrls: [String]) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)

        self.policies = policies
        acceptButton.isEnabled = true

        refreshViews()
    }

    private func renderAccepting() {
        activityPresenter.presentActivityIndicator(on: view, animated: true)
    }

    private func renderAccepted() {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
    }
    
    private func render(error: Error) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }

    private func refreshViews() {
        tableView.reloadData()
    }

    // MARK: - Actions

    @IBAction private func acceptButtonAction(_ sender: Any) {
        viewModel.process(viewAction: .accept)
    }

    @IBAction private func declineButtonAction(_ sender: Any) {
        viewModel.process(viewAction: .decline)
    }
}

// MARK: - ServiceTermsModalScreenViewModelViewDelegate

extension ServiceTermsModalScreenViewController: ServiceTermsModalScreenViewModelViewDelegate {
    func serviceTermsModalScreenViewModel(_ viewModel: ServiceTermsModalScreenViewModelType, didUpdateViewState viewSate: ServiceTermsModalScreenViewState) {
        render(viewState: viewSate)
    }
}

// MARK: - UITableViewDataSource

extension ServiceTermsModalScreenViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        // Use individual sections for each policy so the cells aren't grouped together.
        policies.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Reduce the height between sections to only be the footer height value.
        CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        // Modify the footer size to reduce cell spacing.
        8.0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellReuseIdentifier, for: indexPath)

        let policy = policies[indexPath.section]

        cell.textLabel?.text = policy.name
        cell.textLabel?.textColor = theme.colors.primaryContent
        cell.textLabel?.font = theme.fonts.body
        cell.vc_setAccessoryDisclosureIndicator(withTheme: theme)
        cell.accessoryView?.tintColor = theme.colors.quarterlyContent
        cell.backgroundColor = theme.colors.background
        cell.selectionStyle = .default

        return cell
    }
}

// MARK: - UITableViewDelegate

extension ServiceTermsModalScreenViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let policy = policies[indexPath.section]
        viewModel.process(viewAction: .display(policy))
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - ServiceTermsModalTableHeaderViewDelegate

extension ServiceTermsModalScreenViewController: ServiceTermsModalTableHeaderViewDelegate {
    func tableHeaderViewDidTapInformationButton() {
        let title: String
        let message: String
        
        if viewModel.serviceType == MXServiceTypeIdentityService {
            title = VectorL10n.serviceTermsModalInformationTitleIdentityServer
            message = VectorL10n.serviceTermsModalInformationDescriptionIdentityServer
        } else {
            title = VectorL10n.serviceTermsModalInformationTitleIntegrationManager
            message = VectorL10n.serviceTermsModalInformationDescriptionIntegrationManager
        }
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: VectorL10n.ok, style: .default))
        
        present(alertController, animated: true)
    }
}
