/*
 Copyright 2018 New Vector Ltd

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

import Foundation
import Reusable

final class TermsView: UIView, NibOwnerLoadable, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var acceptButton: UIButton!

    @objc weak var delegate: MXKAuthInputsViewDelegate?

    private var acceptedCallback: (() -> Void)?


    /// NavigationVC to display a policy content
    private var navigationController: RiotNavigationController?

    /// The list of policies to be accepted by the end user
    private var policies: [MXLoginPolicyData] = []

    /// Policies already accepted by the end user
    /// Combined with `policies`, this is the view model for `tableView`
    private var acceptedPolicies: Set<Int> = []

    /// The index of the policy being displayed fullscreen within `navigationController`
    private var displayedPolicyIndex: Int?


    // MARK: - Setup

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNibContent()
        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNibContent()
        commonInit()
    }

    private func commonInit() {

        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(TableViewCellWithCheckBoxAndLabel.nib(), forCellReuseIdentifier: TableViewCellWithCheckBoxAndLabel.defaultReuseIdentifier())

        acceptButton.clipsToBounds = true
        acceptButton.setTitle(VectorL10n.accept, for: .normal)
        acceptButton.setTitle(VectorL10n.accept, for: .highlighted)
        
        acceptButton.layer.masksToBounds = true
        acceptButton.layer.cornerRadius = 5

        customizeViewRendering()
    }

    func customizeViewRendering() {
        self.backgroundColor = UIColor.clear
        self.tableView.backgroundColor = UIColor.clear
        acceptButton.backgroundColor = ThemeService.shared().theme.tintColor
    }


    // MARK: - Public

    /// Display a list of policies the end user must accept.
    ///
    /// - Parameters:
    ///   - terms: Terms data sent by the homeserver.
    ///   - onAccepted: block called when the user has accepted all of them.
    @objc func displayTerms(terms: MXLoginTerms, onAccepted: @escaping () -> Void) {

        acceptedCallback = onAccepted

        let lang: String? = Bundle.mxk_language()

        policies = terms.policiesData(forLanguage: lang, defaultLanguage: "en")
        acceptedPolicies.removeAll()

        reload()
    }


    // MARK: - Private

    private func reload() {
        tableView.reloadData()

        // Enable the button only if the user has accepted all policies
        acceptButton.isEnabled = (policies.count == acceptedPolicies.count)
        acceptButton.alpha = acceptButton.isEnabled ? 1 : 0.5
    }

    @IBAction private func didAcceptButtonTapped(_ sender: Any) {
        if policies.count == acceptedPolicies.count {
            acceptedCallback?()
        }
    }


    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return policies.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellWithCheckBoxAndLabel.defaultReuseIdentifier(), for: indexPath) as? TableViewCellWithCheckBoxAndLabel else {
            fatalError("\(String(describing: TableViewCellWithCheckBoxAndLabel.self)) should be registered")
        }

        let policy = policies[indexPath.row]
        let accepted = acceptedPolicies .contains(indexPath.row)

        cell.label.text = policy.name
        cell.isEnabled = accepted
        cell.vc_setAccessoryDisclosureIndicatorWithCurrentTheme()
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        self.displayPolicy(policyIndex: indexPath.row)
    }

    @objc private func didTapCheckbox(sender: UITapGestureRecognizer) {

        guard let policyIndex = sender.view?.tag else {
            return
        }

        if acceptedPolicies.contains(policyIndex) {
            acceptedPolicies.remove(policyIndex)
        } else {
            acceptedPolicies.insert(policyIndex)
        }

        reload()
    }


    // MARK: - Policy content display

    func displayPolicy(policyIndex: Int) {

        displayedPolicyIndex = policyIndex
        let policy = policies[policyIndex]

        // Display the policy webpage into our webview
        let webViewViewController: WebViewViewController = WebViewViewController(url: policy.url)
        webViewViewController.title = policy.name

        let leftBarButtonItem: UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_icon"), style: .plain, target: self, action: #selector(didTapCancelOnPolicyScreen))
        webViewViewController.navigationItem.leftBarButtonItem = leftBarButtonItem

        navigationController = RiotNavigationController()
        delegate?.authInputsView?(nil, present: navigationController, animated: false)
        navigationController?.pushViewController(webViewViewController, animated: false)
    }

    @objc private func didTapCancelOnPolicyScreen() {
        removePolicyScreen()
    }

    private func removePolicyScreen() {
        displayedPolicyIndex = nil

        navigationController?.dismiss(animated: false)
        navigationController = nil
    }
}
