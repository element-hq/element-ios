// File created from ScreenTemplate
// $ createScreen.sh ReactionHistory ReactionHistory
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

final class ReactionHistoryViewController: UIViewController {
    // MARK: - Constants
    
    private enum TableView {
        static let estimatedRowHeight: CGFloat = 21.0
        static let contentInset = UIEdgeInsets(top: 10.0, left: 0.0, bottom: 10.0, right: 0.0)
    }
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private var tableView: UITableView!
    
    // MARK: Private

    private var viewModel: ReactionHistoryViewModelType!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    private var isViewAppearedOnce = false
    
    private var reactionHistoryViewDataList: [ReactionHistoryViewData] = []
    
    // MARK: - Setup
    
    class func instantiate(with viewModel: ReactionHistoryViewModelType) -> ReactionHistoryViewController {
        let viewController = StoryboardScene.ReactionHistoryViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        title = VectorL10n.reactionHistoryTitle
        
        viewModel.viewDelegate = self
        
        activityPresenter = ActivityIndicatorPresenter()
        errorPresenter = MXKErrorAlertPresentation()
        
        setupViews()
        
        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
        
        viewModel.process(viewAction: .loadMore)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isViewAppearedOnce == false {
            isViewAppearedOnce = true
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        view.backgroundColor = theme.headerBackgroundColor
        tableView.backgroundColor = theme.backgroundColor
        
        if let navigationBar = navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    private func setupTableView() {
        tableView.contentInset = TableView.contentInset
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = TableView.estimatedRowHeight
        tableView.register(cellType: ReactionHistoryViewCell.self)
        
        tableView.tableFooterView = UIView()
    }
    
    private func setupViews() {
        let closeBarButtonItem = MXKBarButtonItem(title: VectorL10n.close, style: .plain) { [weak self] in
            self?.closeButtonAction()
        }
        
        navigationItem.rightBarButtonItem = closeBarButtonItem
        
        setupTableView()
    }

    private func render(viewState: ReactionHistoryViewState) {
        switch viewState {
        case .loading:
            renderLoading()
        case .loaded(reactionHistoryViewDataList: let reactionHistoryViewDataList, allDataLoaded: let allDataLoaded):
            renderLoaded(reactionHistoryViewDataList: reactionHistoryViewDataList, allDataLoaded: allDataLoaded)
        case .error(let error):
            render(error: error)
        }
    }
    
    private func renderLoading() {
        activityPresenter.presentActivityIndicator(on: view, animated: true)
    }
    
    private func renderLoaded(reactionHistoryViewDataList: [ReactionHistoryViewData], allDataLoaded: Bool) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.reactionHistoryViewDataList = reactionHistoryViewDataList
        tableView.reloadData()
    }
    
    private func render(error: Error) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }
    
    // MARK: - Actions

    private func closeButtonAction() {
        viewModel.process(viewAction: .close)
    }
}

// MARK: - UITableViewDataSource

extension ReactionHistoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        reactionHistoryViewDataList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reactionHistoryCell = tableView.dequeueReusableCell(for: indexPath, cellType: ReactionHistoryViewCell.self)

        let reactionHistoryViewData = reactionHistoryViewDataList[indexPath.row]

        reactionHistoryCell.update(theme: theme)
        reactionHistoryCell.fill(with: reactionHistoryViewData)

        return reactionHistoryCell
    }
}

// MARK: - UITableViewDelegate

extension ReactionHistoryViewController: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard isViewAppearedOnce else {
            return
        }
        
        // Check if a scroll beyond scroll view content occurs
        let distanceFromBottom = scrollView.contentSize.height - scrollView.contentOffset.y
        if distanceFromBottom < scrollView.frame.size.height {
            viewModel.process(viewAction: .loadMore)
        }
    }
}

// MARK: - ReactionHistoryViewModelViewDelegate

extension ReactionHistoryViewController: ReactionHistoryViewModelViewDelegate {
    func reactionHistoryViewModel(_ viewModel: ReactionHistoryViewModelType, didUpdateViewState viewSate: ReactionHistoryViewState) {
        render(viewState: viewSate)
    }
}
