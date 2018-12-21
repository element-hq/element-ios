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

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var acceptButton: UIButton!

    @objc weak var delegate: MXKAuthInputsViewDelegate?

    private var acceptedCallback: (()->Void)?


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

    override func layoutSubviews() {
        super.layoutSubviews()

        acceptButton.layer.cornerRadius = 5
    }

    private func commonInit() {

        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(TableViewCellWithCheckBoxAndLabel.nib(), forCellReuseIdentifier: TableViewCellWithCheckBoxAndLabel.defaultReuseIdentifier())

        acceptButton.clipsToBounds = true
        acceptButton.setTitle(NSLocalizedString("accept", tableName: "Vector", comment: ""), for: .normal)
        acceptButton.setTitle(NSLocalizedString("accept", tableName: "Vector", comment: ""), for: .highlighted)

        customizeViewRendering()
    }

    func customizeViewRendering() {
        acceptButton.backgroundColor = RiotDesignValues.colorValues().accent
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

    @IBAction func didAcceptButtonTapped(_ sender: Any) {
        if policies.count == acceptedPolicies.count {
            acceptedCallback?()
        }
    }


    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return policies.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellWithCheckBoxAndLabel.defaultReuseIdentifier(), for: indexPath) as! TableViewCellWithCheckBoxAndLabel

        let policy = policies[indexPath.row]
        let accepted = acceptedPolicies .contains(indexPath.row)

        cell.label.text = policy.name
        cell.isEnabled = accepted
        cell.accessoryType = .disclosureIndicator


        let gesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapCheckbox))
        gesture.numberOfTapsRequired = 1
        gesture.numberOfTouchesRequired = 1

        cell.checkBox.tag = indexPath.row

        cell.checkBox?.isUserInteractionEnabled = true
        if (cell.checkBox?.gestureRecognizers?.count == 0) {
            cell.checkBox?.addGestureRecognizer(gesture)
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

        let leftBarButtonItem: UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_icon"), style: .plain, target: self, action:#selector(didTapCancelOnPolicyScreen))
        webViewViewController.navigationItem.leftBarButtonItem = leftBarButtonItem

        let rightBarButtonItem: UIBarButtonItem = UIBarButtonItem(title: NSLocalizedString("accept", tableName: "Vector", comment: ""), style: .plain, target: self, action: #selector(didAcceptPolicy))
        webViewViewController.navigationItem.rightBarButtonItem = rightBarButtonItem

        navigationController = RiotNavigationController()
        delegate?.authInputsView?(nil, present: navigationController, animated: false)
        navigationController?.pushViewController(webViewViewController, animated: false)
    }

    @objc private func didTapCancelOnPolicyScreen() {
        removePolicyScreen()
    }

    @objc private func didAcceptPolicy() {

        if let displayedPolicyIndex = self.displayedPolicyIndex {
            acceptedPolicies.insert(displayedPolicyIndex)
        }

        removePolicyScreen()
        reload()
    }

    private func removePolicyScreen() {
        displayedPolicyIndex = nil

        navigationController?.dismiss(animated: false)
        navigationController = nil
    }
}
