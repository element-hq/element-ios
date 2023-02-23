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
    private var hasMore: Bool = false
    private let addRoomHeaderView = AddItemHeaderView.instantiate(title: VectorL10n.spacesAddRoom, icon: Asset.Images.spaceAddRoom.image)

    private var itemDataList: [SpaceExploreRoomListItemViewData] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    private var emptyViewArtwork: UIImage {
        return ThemeService.shared().isCurrentThemeDark() ? Asset.Images.roomsEmptyScreenArtworkDark.image : Asset.Images.roomsEmptyScreenArtwork.image
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
        
        self.setupViews()
        self.keyboardAvoider = KeyboardAvoider(scrollViewContainerView: self.view, scrollView: self.tableView)
        self.activityPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = MXKErrorAlertPresentation()
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        self.viewModel.viewDelegate = self

        self.viewModel.process(viewAction: .loadData)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.keyboardAvoider?.startAvoiding()
        AnalyticsScreenTracker.trackScreen(.spaceExploreRooms)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let spaceRoom = self.viewModel.space?.room {
            Analytics.shared.trackViewRoom(spaceRoom)
        }
        Analytics.shared.exploringSpace = self.viewModel.space
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.keyboardAvoider?.stopAvoiding()
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

        self.titleView.update(theme: theme)
        self.tableView.backgroundColor = theme.colors.background
        self.tableView.reloadData()
        theme.applyStyle(onSearchBar: self.tableSearchBar)
        
        self.addRoomHeaderView.update(theme: theme)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        if viewModel.showCancelMenuItem {
            let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
                self?.cancelButtonAction()
            }
            
            let longTitleLabel = UILabel()
                longTitleLabel.text = "STVDIO SPACE"
                longTitleLabel.font = UIFont(name: "Semibold", size: 15)
                longTitleLabel.textColor = .white
//                longTitleLabel.sizeToFit()

            let leftItem = UIBarButtonItem(customView: longTitleLabel)
                self.navigationItem.leftBarButtonItem = leftItem
            
//            self.navigationItem.leftBarButtonItem = cancelBarButtonItem
        }

        self.vc_removeBackTitle()

        self.titleView = MainTitleView()
        self.titleView.titleLabel.text = VectorL10n.titleRooms
        self.navigationItem.titleView = self.titleView
        
        self.tableSearchBar.placeholder = VectorL10n.searchDefaultPlaceholder

        self.tableView.keyboardDismissMode = .interactive
        self.setupTableView()
        
        self.setupTableViewHeader()
    }
    
    private func setupJoinButton(canJoin: Bool) {
        if canJoin {
            let joinButtonItem = MXKBarButtonItem(title: VectorL10n.join, style: .done) { [weak self] in
                self?.viewModel.process(viewAction: .joinOpenedSpace)
            }
            
            self.navigationItem.rightBarButtonItem = joinButtonItem
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }
    }
    
    private func setupTableViewHeader() {
        addRoomHeaderView.delegate = self
        tableView.tableHeaderView = addRoomHeaderView
    }

    private func setupTableView() {
        self.tableView.separatorStyle = .none
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = Constants.estimatedRowHeight
        self.tableView.allowsSelection = true
        self.tableView.register(cellType: SpaceChildViewCell.self)
        self.tableView.register(cellType: SpaceChildSpaceViewCell.self)
        self.tableView.register(cellType: PaginationLoadingViewCell.self)
        self.tableView.tableFooterView = UIView()
    }

    private func render(viewState: SpaceExploreRoomViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .spaceNameFound(let spaceName):
            self.titleView.breadcrumbView.breadcrumbs = [spaceName]
        case .loaded(let children, let hasMore):
            self.hasMore = hasMore
            self.renderLoaded(children: children)
        case .emptySpace:
            self.renderEmptySpace()
        case .emptyFilterResult:
            self.renderEmptyFilterResult()
        case .error(let error):
            self.render(error: error)
        case .canJoin(let canJoin):
            self.setupJoinButton(canJoin: canJoin)
        }
    }
    
    private func renderLoading() {
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
    }
    
    private func renderLoaded(children: [SpaceExploreRoomListItemViewData]) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.itemDataList = children
    }
    
    private func render(error: Error) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }

    private func renderEmptySpace() {
        self.renderLoaded(children: [])
    }

    private func renderEmptyFilterResult() {
        self.renderLoaded(children: [])
    }
    
    // MARK: - Actions

    private func cancelButtonAction() {
        self.viewModel.process(viewAction: .cancel)
    }
    
    // MARK: - UISearchBarDelegate
    
    override func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.viewModel.process(viewAction: .searchChanged(searchText))
    }
}

// MARK: - UITableViewDataSource
extension SpaceExploreRoomViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.itemDataList.count + (self.hasMore ? 1 : 0)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < self.itemDataList.count else {
            let cell = tableView.dequeueReusableCell(for: indexPath, cellType: PaginationLoadingViewCell.self)
            cell.update(theme: self.theme)
            return cell
        }
        
        let viewData = self.itemDataList[indexPath.row]
        
        let cell = viewData.childInfo.roomType == .space ? tableView.dequeueReusableCell(for: indexPath, cellType: SpaceChildSpaceViewCell.self) : tableView.dequeueReusableCell(for: indexPath, cellType: SpaceChildViewCell.self)
        
        cell.update(theme: self.theme)
        cell.fill(with: viewData)
        cell.selectionStyle = .none
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension SpaceExploreRoomViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.viewModel.process(viewAction: .complete(self.itemDataList[indexPath.row], tableView.cellForRow(at: indexPath)))
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if self.hasMore && indexPath.row >= self.itemDataList.count {
            self.viewModel.process(viewAction: .loadData)
        }
    }
    
    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let viewData = self.itemDataList[indexPath.row]
        return UIContextMenuConfiguration(identifier: nil) {
            let viewModel = SpaceChildContextPreviewViewModel(childInfo: viewData.childInfo)
            return RoomContextPreviewViewController.instantiate(with: viewModel, mediaManager: self.viewModel.space?.room?.mxSession.mediaManager)
        } actionProvider: { suggestedActions in
            return self.viewModel.contextMenu(for: self.itemDataList[indexPath.row])
        }
    }
}

// MARK: - SpaceExploreRoomViewModelViewDelegate
extension SpaceExploreRoomViewController: SpaceExploreRoomViewModelViewDelegate {

    func spaceExploreRoomViewModel(_ viewModel: SpaceExploreRoomViewModelType, didUpdateViewState viewSate: SpaceExploreRoomViewState) {
        self.render(viewState: viewSate)
    }
}

// MARK: - SpaceMemberListViewModelViewDelegate
extension SpaceExploreRoomViewController: AddItemHeaderViewDelegate {
    
    func addItemHeaderView(_ headerView: AddItemHeaderView, didTapButton button: UIButton) {
        self.viewModel.process(viewAction: .addRoom)
    }
    
}
