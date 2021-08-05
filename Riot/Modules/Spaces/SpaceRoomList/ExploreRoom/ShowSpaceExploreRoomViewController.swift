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

final class ShowSpaceExploreRoomViewController: UIViewController {
    
    // MARK: - Constants
    
    private enum Constants {
        static let estimatedRowHeight: CGFloat = 64
    }

    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private var tableView: UITableView!
    
    // MARK: Private

    private var viewModel: ShowSpaceExploreRoomViewModelType!
    private var theme: Theme!
    private var keyboardAvoider: KeyboardAvoider?
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    private var titleView: MainTitleView!
    
    private var itemDataList: [SpaceExploreRoomListItemViewData] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    // MARK: - Setup
    
    class func instantiate(with viewModel: ShowSpaceExploreRoomViewModelType) -> ShowSpaceExploreRoomViewController {
        let viewController = StoryboardScene.ShowSpaceExploreRoomViewController.initialScene.instantiate()
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
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        self.titleView = MainTitleView()
        self.titleView.titleLabel.text = VectorL10n.titleRooms
        self.navigationItem.titleView = self.titleView
        
        self.tableView.keyboardDismissMode = .interactive
        self.setupTableView()
    }
    
    private func setupTableView() {
        self.tableView.separatorStyle = .none
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = Constants.estimatedRowHeight
        self.tableView.allowsSelection = true
        self.tableView.register(cellType: SpaceChildViewCell.self)
        self.tableView.tableFooterView = UIView()
    }

    private func render(viewState: ShowSpaceExploreRoomViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .spaceNameFound(let spaceName):
            self.titleView.subtitleLabel.text = spaceName
        case .loaded(let children):
            self.renderLoaded(children: children)
        case .error(let error):
            self.render(error: error)
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
extension ShowSpaceExploreRoomViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.itemDataList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: SpaceChildViewCell.self)
        
        let viewData = self.itemDataList[indexPath.row]
        
        cell.update(theme: self.theme)
        cell.fill(with: viewData)
        cell.selectionStyle = .none
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ShowSpaceExploreRoomViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.viewModel.process(viewAction: .complete(self.itemDataList[indexPath.row]))
    }
}

// MARK: - ShowSpaceExploreRoomViewModelViewDelegate
extension ShowSpaceExploreRoomViewController: ShowSpaceExploreRoomViewModelViewDelegate {

    func showSpaceExploreRoomViewModel(_ viewModel: ShowSpaceExploreRoomViewModelType, didUpdateViewState viewSate: ShowSpaceExploreRoomViewState) {
        self.render(viewState: viewSate)
    }
}
