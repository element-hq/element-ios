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
    @IBOutlet private weak var declineButton: UIButton!

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

        theme.applyStyle(onButton: self.declineButton)
        self.declineButton.setTitleColor(self.theme.warningColor, for: .normal)

        self.refreshViews()
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
        
        self.messageLabel.text = VectorL10n.serviceTermsModalMessage(self.viewModel.serviceUrl)

        self.acceptButton.setTitle(VectorL10n.serviceTermsModalAcceptButton, for: .normal)
        self.acceptButton.setTitle(VectorL10n.serviceTermsModalAcceptButton, for: .highlighted)
        self.refreshAcceptButton()

        if self.viewModel.outOfContext
            && self.viewModel.serviceType == MXServiceTypeIdentityService {
            self.title = VectorL10n.serviceTermsModalTitleIdentityServer
            self.messageLabel.text = VectorL10n.serviceTermsModalMessageIdentityServer(self.viewModel.serviceUrl)

            self.declineButton.setTitle(VectorL10n.serviceTermsModalDeclineButton, for: .normal)
            self.declineButton.setTitle(VectorL10n.serviceTermsModalDeclineButton, for: .highlighted)
        } else {
            self.declineButton.isHidden = true
        }
    }

    private func setupTableView() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.separatorStyle = .none
        self.tableView.alwaysBounceVertical = false
        self.tableView.backgroundColor = .clear
        self.tableView.register(TableViewCellWithCheckBoxAndLabel.nib(), forCellReuseIdentifier: TableViewCellWithCheckBoxAndLabel.defaultReuseIdentifier())
    }

    private func render(viewState: ServiceTermsModalScreenViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .loaded(let policies, let alreadyAcceptedPoliciesUrls):
            self.renderLoaded(policies: policies, alreadyAcceptedPoliciesUrls: alreadyAcceptedPoliciesUrls)
        case .accepted:
            self.renderAccepted()
        case .error(let error):
            self.render(error: error)
        }
    }

    private func renderLoading() {
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
    }

    private func renderLoaded(policies: [MXLoginPolicyData], alreadyAcceptedPoliciesUrls: [String]) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)

        self.policies = policies
        self.updateCheckedPolicies(with: alreadyAcceptedPoliciesUrls)

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

    // Pre-check policies already accepted by the user
    private func updateCheckedPolicies(with acceptedPoliciesUrls: [String]) {
        for url in acceptedPoliciesUrls {
            if let policyIndex = self.policies.firstIndex(where: { $0.url == url }) {
                checkedPolicies.insert(policyIndex)
            }
        }
    }

    
    // MARK: - Actions

    @IBAction private func acceptButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .accept)
    }

    @IBAction private func declineButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .decline)
    }
    
    private func cancelButtonAction() {
        self.viewModel.process(viewAction: .cancel)
    }

    @objc private func didTapCheckbox(sender: UITapGestureRecognizer) {

        guard let policyIndex = sender.view?.tag else {
            return
        }
        
        let isCheckBoxSelected: Bool

        if self.checkedPolicies.contains(policyIndex) {
            self.checkedPolicies.remove(policyIndex)
            isCheckBoxSelected = false
        } else {
            checkedPolicies.insert(policyIndex)
            isCheckBoxSelected = true
        }
        
        if let checkBoxImageView = sender.view as? UIImageView {
            if isCheckBoxSelected {
                checkBoxImageView.accessibilityTraits.insert(.selected)
            } else {
                checkBoxImageView.accessibilityTraits.remove(.selected)
            }
        }

        self.refreshViews()
    }
}


// MARK: - ServiceTermsModalScreenViewModelViewDelegate
extension ServiceTermsModalScreenViewController: ServiceTermsModalScreenViewModelViewDelegate {

    func serviceTermsModalScreenViewModel(_ viewModel: ServiceTermsModalScreenViewModelType, didUpdateViewState viewSate: ServiceTermsModalScreenViewState) {
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

        cell.label.attributedText = self.cellLabel(for: policy)
        cell.label.font = .systemFont(ofSize: 15)
        cell.isEnabled = checked
        cell.vc_setAccessoryDisclosureIndicator(withTheme: self.theme)
        cell.backgroundColor = self.theme.backgroundColor

        if let checkBox = cell.checkBox, checkBox.gestureRecognizers?.isEmpty ?? true {
            let gesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapCheckbox))
            gesture.numberOfTapsRequired = 1
            gesture.numberOfTouchesRequired = 1

            checkBox.isUserInteractionEnabled = true
            checkBox.tag = indexPath.row
            checkBox.addGestureRecognizer(gesture)
            
            checkBox.isAccessibilityElement = true
            checkBox.accessibilityTraits = .button
            checkBox.accessibilityLabel = VectorL10n.accessibilityCheckboxLabel
            checkBox.accessibilityHint = VectorL10n.serviceTermsModalPolicyCheckboxAccessibilityHint(policy.name)
        }

        return cell
    }

    func cellLabel(for policy: MXLoginPolicyData) -> NSAttributedString {

        // TableViewCellWithCheckBoxAndLabel does not have a detailTextLabel
        // Do it by hand

        var labelDetail: String = ""
        switch self.viewModel.serviceType {
        case MXServiceTypeIdentityService:
            labelDetail = VectorL10n.serviceTermsModalDescriptionForIdentityServer1
                + "\n"
                + VectorL10n.serviceTermsModalDescriptionForIdentityServer2
        case MXServiceTypeIntegrationManager:
            labelDetail = VectorL10n.serviceTermsModalDescriptionForIntegrationManager
        default: break
        }

        let label = NSMutableAttributedString(string: policy.name,
                                              attributes: [.foregroundColor: theme.textPrimaryColor])
        label.append(NSAttributedString(string: "\n"))
        label.append(NSAttributedString(string: labelDetail,
                                        attributes: [.foregroundColor: theme.textSecondaryColor]))
        return label
    }
}

extension ServiceTermsModalScreenViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let policy = policies[indexPath.row]
        self.viewModel.process(viewAction: .display(policy))
    }
}
