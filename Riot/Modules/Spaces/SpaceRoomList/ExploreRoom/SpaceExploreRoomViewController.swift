// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceRoomList/ExploreRoom ShowSpaceExploreRoom
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

final class SpaceExploreRoomViewController: UIViewController {
    // MARK: - Constants
    
    private enum Constants {
        static let estimatedRowHeight: CGFloat = 64
    }

    // MARK: Outlets

    @IBOutlet private var tableSearchBar: UISearchBar!
    @IBOutlet private var tableView: UITableView!
    
    // MARK: Private

    private var viewModel: SpaceExploreRoomViewModelType!
    private var theme: Theme!
    private var keyboardAvoider: KeyboardAvoider?
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    private var titleView: MainTitleView!
    private var hasMore = false
    private let addRoomHeaderView = AddItemHeaderView.instantiate(title: VectorL10n.spacesAddRoom, icon: Asset.Images.spaceAddRoom.image)

    private var itemDataList: [SpaceExploreRoomListItemViewData] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    private var emptyViewArtwork: UIImage {
        ThemeService.shared().isCurrentThemeDark() ? Asset.Images.roomsEmptyScreenArtworkDark.image : Asset.Images.roomsEmptyScreenArtwork.image
    }
    
    // MARK: - Setup
    
    class func instantiate(with viewModel: SpaceExploreRoomViewModelType) -> SpaceExploreRoomViewController {
        let viewController = StoryboardScene.SpaceExploreRoomViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        setupViews()
        keyboardAvoider = KeyboardAvoider(scrollViewContainerView: view, scrollView: tableView)
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
        AnalyticsScreenTracker.trackScreen(.spaceExploreRooms)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let spaceRoom = viewModel.space?.room {
            Analytics.shared.trackViewRoom(spaceRoom)
        }
        Analytics.shared.exploringSpace = viewModel.space
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

        titleView.update(theme: theme)
        tableView.backgroundColor = theme.colors.background
        tableView.reloadData()
        theme.applyStyle(onSearchBar: tableSearchBar)
        
        addRoomHeaderView.update(theme: theme)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        if viewModel.showCancelMenuItem {
            let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
                self?.cancelButtonAction()
            }
            
            navigationItem.leftBarButtonItem = cancelBarButtonItem
        }

        vc_removeBackTitle()

        titleView = MainTitleView()
        titleView.titleLabel.text = VectorL10n.titleRooms
        navigationItem.titleView = titleView
        
        tableSearchBar.placeholder = VectorL10n.searchDefaultPlaceholder

        tableView.keyboardDismissMode = .interactive
        setupTableView()
        
        setupTableViewHeader()
    }
    
    private func setupJoinButton(canJoin: Bool) {
        if canJoin {
            let joinButtonItem = MXKBarButtonItem(title: VectorL10n.join, style: .done) { [weak self] in
                self?.viewModel.process(viewAction: .joinOpenedSpace)
            }
            
            navigationItem.rightBarButtonItem = joinButtonItem
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    private func setupTableViewHeader() {
        addRoomHeaderView.delegate = self
        tableView.tableHeaderView = addRoomHeaderView
    }

    private func setupTableView() {
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Constants.estimatedRowHeight
        tableView.allowsSelection = true
        tableView.register(cellType: SpaceChildViewCell.self)
        tableView.register(cellType: SpaceChildSpaceViewCell.self)
        tableView.register(cellType: PaginationLoadingViewCell.self)
        tableView.tableFooterView = UIView()
    }

    private func render(viewState: SpaceExploreRoomViewState) {
        switch viewState {
        case .loading:
            renderLoading()
        case .spaceNameFound(let spaceName):
            titleView.breadcrumbView.breadcrumbs = [spaceName]
        case .loaded(let children, let hasMore):
            self.hasMore = hasMore
            renderLoaded(children: children)
        case .emptySpace:
            renderEmptySpace()
        case .emptyFilterResult:
            renderEmptyFilterResult()
        case .error(let error):
            render(error: error)
        case .canJoin(let canJoin):
            setupJoinButton(canJoin: canJoin)
        }
    }
    
    private func renderLoading() {
        activityPresenter.presentActivityIndicator(on: view, animated: true)
    }
    
    private func renderLoaded(children: [SpaceExploreRoomListItemViewData]) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        itemDataList = children
    }
    
    private func render(error: Error) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }

    private func renderEmptySpace() {
        renderLoaded(children: [])
    }

    private func renderEmptyFilterResult() {
        renderLoaded(children: [])
    }
    
    // MARK: - Actions

    private func cancelButtonAction() {
        viewModel.process(viewAction: .cancel)
    }
    
    // MARK: - UISearchBarDelegate
    
    override func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.process(viewAction: .searchChanged(searchText))
    }
}

// MARK: - UITableViewDataSource

extension SpaceExploreRoomViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        itemDataList.count + (hasMore ? 1 : 0)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < itemDataList.count else {
            let cell = tableView.dequeueReusableCell(for: indexPath, cellType: PaginationLoadingViewCell.self)
            cell.update(theme: theme)
            return cell
        }
        
        let viewData = itemDataList[indexPath.row]
        
        let cell = viewData.childInfo.roomType == .space ? tableView.dequeueReusableCell(for: indexPath, cellType: SpaceChildSpaceViewCell.self) : tableView.dequeueReusableCell(for: indexPath, cellType: SpaceChildViewCell.self)
        
        cell.update(theme: theme)
        cell.fill(with: viewData)
        cell.selectionStyle = .none
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension SpaceExploreRoomViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.process(viewAction: .complete(itemDataList[indexPath.row], tableView.cellForRow(at: indexPath)))
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if hasMore, indexPath.row >= itemDataList.count {
            viewModel.process(viewAction: .loadData)
        }
    }
    
    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let viewData = itemDataList[indexPath.row]
        return UIContextMenuConfiguration(identifier: nil) {
            let viewModel = SpaceChildContextPreviewViewModel(childInfo: viewData.childInfo)
            return RoomContextPreviewViewController.instantiate(with: viewModel, mediaManager: self.viewModel.space?.room?.mxSession.mediaManager)
        } actionProvider: { _ in
            self.viewModel.contextMenu(for: self.itemDataList[indexPath.row])
        }
    }
}

// MARK: - SpaceExploreRoomViewModelViewDelegate

extension SpaceExploreRoomViewController: SpaceExploreRoomViewModelViewDelegate {
    func spaceExploreRoomViewModel(_ viewModel: SpaceExploreRoomViewModelType, didUpdateViewState viewSate: SpaceExploreRoomViewState) {
        render(viewState: viewSate)
    }
}

// MARK: - SpaceMemberListViewModelViewDelegate

extension SpaceExploreRoomViewController: AddItemHeaderViewDelegate {
    func addItemHeaderView(_ headerView: AddItemHeaderView, didTapButton button: UIButton) {
        viewModel.process(viewAction: .addRoom)
    }
}
