// File created from simpleScreenTemplate
// $ createSimpleScreen.sh CallTransfer CallTransferSelectContact
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
import Reusable

protocol CallTransferSelectContactViewControllerDelegate: AnyObject {
    func callTransferSelectContactViewControllerDidSelectContact(_ viewController: CallTransferSelectContactViewController,
                                                                 contact: MXKContact?)
}

final class CallTransferSelectContactViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var mainTableView: UITableView!
    
    // MARK: Private
    
    private enum Constants {
        static let maxNumberOfRecentContacts: UInt = 10
        static let sectionHeaderHeightDefault: CGFloat = 30.0
        static let sectionHeaderHeightHidden: CGFloat = 0.01
    }
    
    private var session: MXSession!
    private var theme: Theme!
    private var contactsDataSource: ContactsDataSource! {
        didSet {
            for userId in ignoredUserIds {
                contactsDataSource.ignoredContactsByMatrixId[userId] = MXKContact()
            }
            contactsDataSource.delegate = self
        }
    }
    private var ignoredUserIds: [String] = []
    private var selectedIndexPath: IndexPath?
    
    private lazy var mainSearchBar: UISearchBar = {
        let searchBar = UISearchBar(frame: CGRect(origin: .zero, size: CGSize(width: mainTableView.frame.width, height: 44)))
        searchBar.delegate = self
        searchBar.placeholder = VectorL10n.searchDefaultPlaceholder
        searchBar.returnKeyType = .done
        return searchBar
    }()
    
    private struct Row {
        var contact: MXKContact
        var accessoryType: UITableViewCell.AccessoryType = .none
    }
    
    private struct Section {
        var header: String?
        var rows: [Row]
    }
    
    private var sections: [Section] = [] {
        didSet {
            mainTableView.reloadData()
        }
    }
    
    // MARK: Public
    
    weak var delegate: CallTransferSelectContactViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate(withSession session: MXSession, ignoredUserIds: [String] = []) -> CallTransferSelectContactViewController {
        let viewController = StoryboardScene.CallTransferSelectContactViewController.initialScene.instantiate()
        viewController.session = session
        viewController.ignoredUserIds = ignoredUserIds
        viewController.contactsDataSource = MatrixContactsDataSource(matrixSession: session)
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.vc_removeBackTitle()
        
        self.setupViews()
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        updateSections()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        MXKContactManager.shared().refreshLocalContacts()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func updateSections() {
        var tmpSections: [Section] = []
        
        let users = session.callManager.getRecentCalledUsers(Constants.maxNumberOfRecentContacts,
                                                             ignoredUserIds: ignoredUserIds)
        var recentRows: [Row] = []
        for (index, user) in users.enumerated() {
            let indexPath = IndexPath(row: index, section: 0)
            let accessoryType: UITableViewCell.AccessoryType = indexPath == selectedIndexPath ? .checkmark : .none
            let row = Row(contact: MXKContact(matrixContactWithDisplayName: user.displayname,
                                              matrixID: user.userId,
                                              andMatrixAvatarURL: user.avatarUrl),
                          accessoryType: accessoryType)
            
            recentRows.append(row)
        }
        let recentsSection = Section(header: VectorL10n.callTransferContactsRecent, rows: recentRows)
        tmpSections.append(recentsSection)
        
        let sectionOffset = tmpSections.count
        
        for section in 0..<contactsDataSource.numberOfSections(in: mainTableView) {
            var rows: [Row] = []
            for row in 0..<contactsDataSource.tableView(mainTableView, numberOfRowsInSection: section) {
                let sourceIndexPath = IndexPath(row: row, section: section)
                let tableIndexPath = IndexPath(row: row, section: section + sectionOffset)
                let accessoryType: UITableViewCell.AccessoryType = tableIndexPath == selectedIndexPath ? .checkmark : .none
                if let contact = contactsDataSource.contact(at: sourceIndexPath) {
                    rows.append(Row(contact: contact,
                                    accessoryType: accessoryType))
                }
            }
            let sectionTitle = rows.isEmpty ? nil : contactsDataSource.tableView(mainTableView, titleForHeaderInSection: section)
            tmpSections.append(Section(header: sectionTitle, rows: rows))
        }
        
        sections = tmpSections
    }
    
    private func setupViews() {
        mainTableView.tableHeaderView = mainSearchBar
        
        mainTableView.register(cellType: ContactTableViewCell.self)
    }
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.headerBackgroundColor
        self.mainTableView.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        theme.applyStyle(onSearchBar: mainSearchBar)
        
        mainTableView.reloadData()
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }

    // MARK: - Actions
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
}

//  MARK: - UITableViewDataSource

extension CallTransferSelectContactViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        
        let cell: ContactTableViewCell = tableView.dequeueReusableCell(for: indexPath)
        
        cell.render(row.contact)
        //  replace presence with user id
        cell.contactInformationLabel.text = row.contact.matrixIdentifiers.first as? String
        
        if row.accessoryType == .checkmark {
            cell.accessoryView = UIImageView(image: Asset.Images.checkmark.image)
        } else {
            cell.accessoryView = nil
            cell.accessoryType = row.accessoryType
        }
        
        return cell
    }
    
}

//  MARK: - UITableViewDelegate

extension CallTransferSelectContactViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = theme.backgroundColor
        cell.selectedBackgroundView = UIView()
        cell.selectedBackgroundView?.backgroundColor = theme.selectedBackgroundColor
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if sections[section].header != nil {
            return Constants.sectionHeaderHeightDefault
        }
        return Constants.sectionHeaderHeightHidden
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if sections[section].header != nil {
            return Constants.sectionHeaderHeightDefault
        }
        return Constants.sectionHeaderHeightHidden
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if selectedIndexPath == indexPath {
            selectedIndexPath = nil
            delegate?.callTransferSelectContactViewControllerDidSelectContact(self, contact: nil)
        } else {
            selectedIndexPath = indexPath
            let contact = sections[indexPath.section].rows[indexPath.row].contact
            delegate?.callTransferSelectContactViewControllerDidSelectContact(self, contact: contact)
        }
        
        updateSections()
    }
    
}

//  MARK: - UISearchBarDelegate

extension CallTransferSelectContactViewController {
    
    override func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        contactsDataSource.search(withPattern: searchText, forceReset: false)
    }
    
    override func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let contact = contactsDataSource.searchInputContact {
            delegate?.callTransferSelectContactViewControllerDidSelectContact(self, contact: contact)
        }
        
        searchBar.resignFirstResponder()
    }
    
    override func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        
        contactsDataSource.search(withPattern: nil, forceReset: false)
        
        searchBar.resignFirstResponder()
    }
    
    override func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        DispatchQueue.main.async {
            searchBar.setShowsCancelButton(true, animated: true)
        }
    }
    
    override func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        DispatchQueue.main.async {
            searchBar.setShowsCancelButton(false, animated: false)
        }
    }
    
}

//  MARK: - MXKDataSourceDelegate

extension CallTransferSelectContactViewController: MXKDataSourceDelegate {
    
    func cellViewClass(for cellData: MXKCellData!) -> MXKCellRendering.Type! {
        return nil
    }
    
    func cellReuseIdentifier(for cellData: MXKCellData!) -> String! {
        return nil
    }
    
    func dataSource(_ dataSource: MXKDataSource!, didCellChange changes: Any!) {
        updateSections()
    }
    
    func dataSource(_ dataSource: MXKDataSource!, didStateChange state: MXKDataSourceState) {
        updateSections()
    }
    
}

extension ContactTableViewCell: Reusable {}
