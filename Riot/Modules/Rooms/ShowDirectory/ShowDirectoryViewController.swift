// File created from ScreenTemplate
// $ createScreen.sh Rooms/ShowDirectory ShowDirectory
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

final class ShowDirectoryViewController: UIViewController {
    
    // MARK: - Constants
    
    private enum Constants {
        static let networkHeaderViewEstimatedHeight: CGFloat = 40.0
    }
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private weak var mainTableView: UITableView!
    @IBOutlet private weak var vibrancyEffectView: UIVisualEffectView!
    @IBOutlet private weak var vibrancyEffectContentView: UIView!
    @IBOutlet private weak var blurEffectView: UIVisualEffectView!
    @IBOutlet private weak var blurEffectContentView: UIView!
    @IBOutlet private weak var createRoomButton: UIButton! {
        didSet {
            createRoomButton.setTitle(VectorL10n.searchableDirectoryCreateNewRoom, for: .normal)
        }
    }
    
    // MARK: Private

    private var viewModel: ShowDirectoryViewModelType!
    private var theme: Theme!
    private var keyboardAvoider: KeyboardAvoider?
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    private lazy var footerSpinnerView: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .whiteLarge)
        spinner.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        spinner.color = .darkGray
        spinner.hidesWhenStopped = false
        spinner.backgroundColor = .clear
        spinner.startAnimating()
        return spinner
    }()
    private lazy var tableFooterView: UIView = {
        let bottomSafeAreaInset = UIApplication.shared.windows.last?.safeAreaInsets.bottom ?? 0
        let height = vibrancyEffectView.frame.height - bottomSafeAreaInset
        return UIView(frame: CGRect(x: 0, y: 0, width: 0, height: height))
    }()
    private lazy var mainSearchBar: UISearchBar = {
        let bar = UISearchBar(frame: CGRect(origin: .zero, size: CGSize(width: 600, height: 44)))
        bar.autoresizingMask = .flexibleWidth
        bar.showsCancelButton = false
        bar.placeholder = VectorL10n.searchableDirectorySearchPlaceholder
        bar.setBackgroundImage(UIImage.vc_image(from: .clear), for: .any, barMetrics: .default)
        bar.delegate = self
        return bar
    }()
    
    private var sections: [ShowDirectorySection] = []
    
    private let screenTracker = AnalyticsScreenTracker(screen: .roomDirectory)

    // MARK: - Setup
    
    class func instantiate(with viewModel: ShowDirectoryViewModelType) -> ShowDirectoryViewController {
        let viewController = StoryboardScene.ShowDirectoryViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.setupViews()
        self.keyboardAvoider = KeyboardAvoider(scrollViewContainerView: self.view, scrollView: self.mainTableView)
        self.activityPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = MXKErrorAlertPresentation()
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        self.viewModel.viewDelegate = self

        self.viewModel.process(viewAction: .loadData(false))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.keyboardAvoider?.startAvoiding()
        screenTracker.trackScreen()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.keyboardAvoider?.stopAvoiding()
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func addSpinnerFooterView() {
        footerSpinnerView.startAnimating()
        self.mainTableView.tableFooterView = footerSpinnerView
    }
    
    private func removeSpinnerFooterView() {
        footerSpinnerView.stopAnimating()
        self.mainTableView.tableFooterView = tableFooterView
    }
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.headerBackgroundColor
        self.mainTableView.backgroundColor = theme.backgroundColor
        self.mainTableView.separatorColor = theme.lineBreakColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
            navigationBar.setBackgroundImage(UIImage.vc_image(from: theme.headerBackgroundColor), for: .default)
        }

        theme.applyStyle(onSearchBar: mainSearchBar)
        theme.applyStyle(onButton: createRoomButton)
        if #available(iOS 13.0, *) {
            vibrancyEffectView.overrideUserInterfaceStyle = theme.userInterfaceStyle
            vibrancyEffectContentView.overrideUserInterfaceStyle = theme.userInterfaceStyle
            blurEffectView.overrideUserInterfaceStyle = theme.userInterfaceStyle
            blurEffectContentView.overrideUserInterfaceStyle = theme.userInterfaceStyle
        }
        
        self.mainTableView.reloadData()
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        self.mainTableView.keyboardDismissMode = .interactive
        self.mainTableView.register(headerFooterViewType: DirectoryNetworkTableHeaderFooterView.self)
        self.mainTableView.register(cellType: DirectoryRoomTableViewCell.self)
        self.mainTableView.rowHeight = 76
        self.mainTableView.tableFooterView = tableFooterView
        
        let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
            self?.cancelButtonAction()
        }
        self.navigationItem.rightBarButtonItem = cancelBarButtonItem
        
        self.navigationItem.titleView = mainSearchBar
    }

    private func render(viewState: ShowDirectoryViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .loaded(let sections):
            self.renderLoaded(sections: sections)
        case .error(let error):
            self.render(error: error)
        }
    }
    
    private func renderLoading() {
        addSpinnerFooterView()
    }
    
    private func renderLoaded(sections: [ShowDirectorySection]) {
        removeSpinnerFooterView()
        self.sections = sections
        self.mainTableView.reloadData()
    }
    
    private func render(error: Error) {
        removeSpinnerFooterView()
        self.errorPresenter.presentError(from: self, forError: error, animated: true) {
            // If the join failed, reload the table view
            self.mainTableView.reloadData()
        }
    }

    // MARK: - Actions

    @IBAction private func createRoomButtonTapped(_ sender: UIButton) {
        viewModel.process(viewAction: .createNewRoom)
    }

    private func cancelButtonAction() {
        self.viewModel.process(viewAction: .cancel)
    }
}


// MARK: - UITableViewDataSource

extension ShowDirectoryViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let directorySection = self.sections[section]
        
        switch directorySection {
        case .searchInput:
            return 1
        case.publicRoomsDirectory(let viewModel):
            return viewModel.roomsCount
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                        
        let section = self.sections[indexPath.section]
        
        let cellViewModel: DirectoryRoomTableViewCellVM?
        
        switch section {
        case .searchInput(let searchInputViewData):
            cellViewModel = searchInputViewData
        case.publicRoomsDirectory(let viewModel):
            cellViewModel = viewModel.roomViewModel(at: indexPath.row)
        }
        
        let cell: DirectoryRoomTableViewCell = tableView.dequeueReusableCell(for: indexPath)
        if let cellViewModel = cellViewModel {
            cell.configure(withViewModel: cellViewModel)
        }
        cell.indexPath = indexPath
        cell.delegate = self
        cell.update(theme: self.theme)
        return cell
    }
    
}

// MARK: - UITableViewDataDelegate

extension ShowDirectoryViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = theme.backgroundColor
        
        // Update the selected background view
        cell.selectedBackgroundView = UIView()
        cell.selectedBackgroundView?.backgroundColor = theme.selectedBackgroundColor
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        viewModel.process(viewAction: .selectRoom(indexPath))
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Trigger inconspicuous pagination when user scrolls down
        if (scrollView.contentSize.height - scrollView.contentOffset.y - scrollView.frame.size.height) < 300 {
            viewModel.process(viewAction: .loadData(false))
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let sectionHeaderView: UIView?
        
        let directorySection = self.sections[section]
        
        switch directorySection {
        case .searchInput:
            sectionHeaderView = nil
        case .publicRoomsDirectory(let viewModel):
            guard let view: DirectoryNetworkTableHeaderFooterView = tableView.dequeueReusableHeaderFooterView() else {
                return nil
            }
            if let name = viewModel.directoryServerDisplayname {
                let title = VectorL10n.searchableDirectoryXNetwork(name)
                view.configure(withViewModel: DirectoryNetworkVM(title: title))
            }
            view.update(theme: self.theme)
            view.delegate = self
            sectionHeaderView = view
        }
        
        return sectionHeaderView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView,
                   estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        let directorySection = self.sections[section]
        
        let estimatedHeight: CGFloat
        
        switch directorySection {
        case .searchInput:
            estimatedHeight = 0.0
        case .publicRoomsDirectory:
            estimatedHeight = Constants.networkHeaderViewEstimatedHeight
        }
        
        return estimatedHeight
    }
}

// MARK: - UISearchBarDelegate

extension ShowDirectoryViewController {
    
    override func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.process(viewAction: .search(searchText))
    }
    
}

// MARK: -

extension ShowDirectoryViewController: DirectoryRoomTableViewCellDelegate {
    
    func directoryRoomTableViewCellDidTapJoin(_ cell: DirectoryRoomTableViewCell) {
        cell.startJoining()
        viewModel.process(viewAction: .joinRoom(cell.indexPath))
    }
    
}

// MARK: - DirectoryNetworkTableHeaderFooterViewDelegate

extension ShowDirectoryViewController: DirectoryNetworkTableHeaderFooterViewDelegate {
    
    func directoryNetworkTableHeaderFooterViewDidTapSwitch(_ view: DirectoryNetworkTableHeaderFooterView) {
        viewModel.process(viewAction: .switchServer)
    }
    
}


// MARK: - ShowDirectoryViewModelViewDelegate
extension ShowDirectoryViewController: ShowDirectoryViewModelViewDelegate {

    func showDirectoryViewModel(_ viewModel: ShowDirectoryViewModelType, didUpdateViewState viewSate: ShowDirectoryViewState) {
        self.render(viewState: viewSate)
    }
}
