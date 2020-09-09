// File created from simpleScreenTemplate
// $ createSimpleScreen.sh Rooms2 SearchableDirectory
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

@objc protocol SearchableDirectoryViewControllerDelegate: NSObjectProtocol {
    func searchableDirectoryViewControllerDidCancel(_ viewController: SearchableDirectoryViewController)
    func searchableDirectoryViewControllerDidSelect(_ viewController: SearchableDirectoryViewController, room: MXPublicRoom)
    func searchableDirectoryViewControllerDidTapCreateNewRoom(_ viewController: SearchableDirectoryViewController)
}

final class SearchableDirectoryViewController: MXKViewController {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var mainTableView: UITableView!
    @IBOutlet private weak var createRoomButton: UIButton! {
        didSet {
            createRoomButton.setTitle(VectorL10n.searchableDirectoryCreateNewRoom, for: .normal)
        }
    }
    
    // MARK: Private
    
    private var theme: Theme!
    private var dataSource: PublicRoomsDirectoryDataSource!
    private lazy var footerSpinnerView: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .whiteLarge)
        spinner.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        spinner.color = .darkGray
        spinner.hidesWhenStopped = false
        spinner.backgroundColor = .clear
        spinner.startAnimating()
        return spinner
    }()
    private lazy var mainSearchBar: UISearchBar = {
        let bar = UISearchBar(frame: CGRect(origin: .zero, size: CGSize(width: 600, height: 44)))
        bar.autoresizingMask = .flexibleWidth
        bar.showsCancelButton = false
        bar.placeholder = VectorL10n.searchDefaultPlaceholder
        bar.setBackgroundImage(UIImage.vc_image(from: .clear), for: .any, barMetrics: .default)
        bar.delegate = self
        return bar
    }()
    
    // MARK: Public
    
    @objc weak var delegate: SearchableDirectoryViewControllerDelegate?
    
    @objc func display(withDataSource dataSource: PublicRoomsDirectoryDataSource) {
        self.dataSource = dataSource
        self.dataSource.delegate = self
        if isViewLoaded {
            self.mainTableView.reloadData()
        }
    }
    
    // MARK: - Setup
    
    @objc class func instantiate(withSession session: MXSession) -> SearchableDirectoryViewController {
        let viewController = StoryboardScene.SearchableDirectoryViewController.initialScene.instantiate()
        viewController.theme = ThemeService.shared().theme
        viewController.addMatrixSession(session)
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.title = "Template"
        self.vc_removeBackTitle()
        
        self.setupViews()
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        self.mainTableView.tableFooterView = UIView()
        
        triggerPagination()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func setupViews() {
        self.mainTableView.register(headerFooterViewType: DirectoryNetworkTableHeaderFooterView.self)
        self.mainTableView.register(cellType: DirectoryRoomTableViewCell.self)
        self.mainTableView.rowHeight = 76
        
        let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
            self?.cancelButtonAction()
        }
        self.navigationItem.rightBarButtonItem = cancelBarButtonItem
        
        self.navigationItem.titleView = mainSearchBar
    }
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.backgroundColor
        self.mainTableView.backgroundColor = theme.backgroundColor
        self.mainTableView.separatorColor = theme.lineBreakColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        theme.applyStyle(onSearchBar: mainSearchBar)
        theme.applyStyle(onButton: createRoomButton)
        
        self.mainTableView.reloadData()
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    private func addSpinnerFooterView() {
        footerSpinnerView.startAnimating()
        self.mainTableView.tableFooterView = footerSpinnerView
    }
    
    private func removeSpinnerFooterView() {
        footerSpinnerView.stopAnimating()
        self.mainTableView.tableFooterView = UIView()
    }
    
    private func triggerPagination(force: Bool = false) {
        if !force && (dataSource.hasReachedPaginationEnd || footerSpinnerView.superview != nil) {
            // We got all public rooms or we are already paginating
            // Do nothing
            return
        }
        
        self.addSpinnerFooterView()
        
        dataSource.paginate({ [weak self] (roomsAdded) in
            guard let self = self else { return }
            if roomsAdded > 0 {
                self.mainTableView.reloadData()
            }
            self.removeSpinnerFooterView()
        }, failure: { [weak self] (error) in
            guard let self = self else { return }
            self.removeSpinnerFooterView()
        })
    }
    
    // MARK: - Override
    
    override func addMatrixSession(_ mxSession: MXSession!) {
        super.addMatrixSession(mxSession)
        
        if dataSource == nil {
            display(withDataSource: PublicRoomsDirectoryDataSource(matrixSession: mxSession))
        }
    }

    // MARK: - Actions
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }

    private func cancelButtonAction() {
        self.delegate?.searchableDirectoryViewControllerDidCancel(self)
    }
    
    @IBAction private func createRoomButtonTapped(_ sender: UIButton) {
        self.delegate?.searchableDirectoryViewControllerDidTapCreateNewRoom(self)
    }
}

// MARK: - UITableViewDataSource

extension SearchableDirectoryViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(dataSource?.roomsCount ?? 0)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: DirectoryRoomTableViewCell = tableView.dequeueReusableCell(for: indexPath)
        if let room = dataSource.room(at: indexPath) {
            cell.configure(withRoom: room, session: dataSource.mxSession)
        }
        cell.update(theme: self.theme)
        return cell
    }
    
}

// MARK: - UITableViewDataDelegate

extension SearchableDirectoryViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = theme.backgroundColor
        
        // Update the selected background view
        cell.selectedBackgroundView = UIView()
        cell.selectedBackgroundView?.backgroundColor = theme.selectedBackgroundColor
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let room = dataSource.room(at: indexPath) else { return }
        delegate?.searchableDirectoryViewControllerDidSelect(self, room: room)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Trigger inconspicuous pagination when user scrolls down
        if (scrollView.contentSize.height - scrollView.contentOffset.y - scrollView.frame.size.height) < 300 {
            self.triggerPagination()
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let view: DirectoryNetworkTableHeaderFooterView = tableView.dequeueReusableHeaderFooterView() else {
            return nil
        }
        if let name = self.dataSource.directoryServerDisplayname {
            let title = VectorL10n.searchableDirectoryXNetwork(name)
            view.configure(withViewModel: DirectoryNetworkVM(title: title))
        }
        view.update(theme: self.theme)
        view.delegate = self
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
}

// MARK: - UISearchBarDelegate

extension SearchableDirectoryViewController {
    
    override func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        dataSource.searchPattern = searchText
        triggerPagination(force: true)
    }
    
}

// MARK: - MXKDataSourceDelegate

extension SearchableDirectoryViewController: MXKDataSourceDelegate {
    
    func cellViewClass(for cellData: MXKCellData!) -> MXKCellRendering.Type! {
        return nil
    }
    
    func cellReuseIdentifier(for cellData: MXKCellData!) -> String! {
        return nil
    }
    
    func dataSource(_ dataSource: MXKDataSource!, didCellChange changes: Any!) {
        
    }
    
    func dataSource(_ dataSource: MXKDataSource!, didStateChange state: MXKDataSourceState) {
        self.mainTableView.reloadData()
    }
    
}

// MARK: - DirectoryNetworkTableHeaderFooterViewDelegate

extension SearchableDirectoryViewController: DirectoryNetworkTableHeaderFooterViewDelegate {
    
    func directoryNetworkTableHeaderFooterViewDidTapSwitch(_ view: DirectoryNetworkTableHeaderFooterView) {
        let controller = DirectoryServerPickerViewController()
        let source = MXKDirectoryServersDataSource(matrixSession: self.mainSession)
        source?.finalizeInitialization()
        source?.roomDirectoryServers = BuildSettings.publicRoomsDirectoryServers
        
        controller.display(with: source) { [weak self] (cellData) in
            guard let self = self else { return }
            guard let cellData = cellData else { return }
            
            if let thirdpartyProtocolInstance = cellData.thirdPartyProtocolInstance {
                self.dataSource.thirdpartyProtocolInstance = thirdpartyProtocolInstance
            } else if let homeserver = cellData.homeserver {
                self.dataSource.includeAllNetworks = cellData.includeAllNetworks
                self.dataSource.homeserver = homeserver
            }
            
            self.triggerPagination()
        }
        
        let navController = RiotNavigationController(rootViewController: controller)
        self.navigationController?.present(navController, animated: true, completion: nil)
    }
    
}
