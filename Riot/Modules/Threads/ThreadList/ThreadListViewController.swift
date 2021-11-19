// File created from ScreenTemplate
// $ createScreen.sh Threads/ThreadList ThreadList
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

final class ThreadListViewController: UIViewController {
    
    // MARK: - Constants
    
    private enum Constants {
        static let aConstant: Int = 666
    }
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private weak var threadsTableView: UITableView!
    
    // MARK: Private

    private var viewModel: ThreadListViewModelProtocol!
    private var theme: Theme!
    private var keyboardAvoider: KeyboardAvoider?
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!

    // MARK: - Setup
    
    class func instantiate(with viewModel: ThreadListViewModelProtocol) -> ThreadListViewController {
        let viewController = StoryboardScene.ThreadListViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.setupViews()
        self.keyboardAvoider = KeyboardAvoider(scrollViewContainerView: self.view, scrollView: self.threadsTableView)
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

        self.threadsTableView.backgroundColor = theme.backgroundColor
        self.threadsTableView.separatorColor = theme.colors.separator
        self.threadsTableView.reloadData()
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        let titleView = ThreadRoomTitleView.loadFromNib()
        titleView.mode = .allThreads
        titleView.viewDelegate = self
        titleView.configure(withViewModel: viewModel.titleViewModel)
        navigationItem.leftItemsSupplementBackButton = true
        navigationItem.backBarButtonItem = UIBarButtonItem(title: nil, style: .plain, target: nil, action: nil)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleView)
        
        self.threadsTableView.tableFooterView = UIView()
        self.threadsTableView.register(cellType: ThreadTableViewCell.self)
        self.threadsTableView.keyboardDismissMode = .interactive
    }

    private func render(viewState: ThreadListViewState) {
        switch viewState {
        case .idle:
            break
        case .loading:
            self.renderLoading()
        case .loaded:
            self.renderLoaded()
        case .showingFilterTypes:
            self.renderShowingFilterTypes()
        case .error(let error):
            self.render(error: error)
        }
    }
    
    private func renderLoading() {
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
    }
    
    private func renderLoaded() {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.threadsTableView.reloadData()
    }
    
    private func renderShowingFilterTypes() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let allThreadsAction = UIAlertAction(title: ThreadListFilterType.all.title,
                                             style: .default,
                                             handler: { [weak self] action in
                                                 guard let self = self else { return }
                                                 self.viewModel.process(viewAction: .selectFilterType(.all))
                                             })
        if self.viewModel.selectedFilterType == .all {
            allThreadsAction.setValue(true, forKey: "checked")
        }
        alertController.addAction(allThreadsAction)
        
        let myThreadsAction = UIAlertAction(title: ThreadListFilterType.myThreads.title,
                                            style: .default,
                                            handler: { [weak self] action in
                                                guard let self = self else { return }
                                                self.viewModel.process(viewAction: .selectFilterType(.myThreads))
                                            })
        if self.viewModel.selectedFilterType == .myThreads {
            myThreadsAction.setValue(true, forKey: "checked")
        }
        alertController.addAction(myThreadsAction)
        
        alertController.addAction(UIAlertAction(title: VectorL10n.cancel,
                                                style: .cancel,
                                                handler: nil))
        
        alertController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func render(error: Error) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }

    // MARK: - Actions

}

// MARK: - ThreadListViewModelViewDelegate

extension ThreadListViewController: ThreadListViewModelViewDelegate {

    func threadListViewModel(_ viewModel: ThreadListViewModelProtocol,
                             didUpdateViewState viewSate: ThreadListViewState) {
        self.render(viewState: viewSate)
    }
}

//  MARK: - UITableViewDataSource

extension ThreadListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfThreads
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ThreadTableViewCell = tableView.dequeueReusableCell(for: indexPath)
        
        if let threadVM = viewModel.threadViewModel(at: indexPath.row) {
            cell.configure(withViewModel: threadVM)
        }
        cell.update(theme: theme)
        
        return cell
    }
    
}

//  MARK: - UITableViewDelegate

extension ThreadListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = theme.backgroundColor
        cell.selectedBackgroundView = UIView()
        cell.selectedBackgroundView?.backgroundColor = theme.selectedBackgroundColor
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        viewModel.process(viewAction: .selectThread(indexPath.row))
    }
    
}

//  MARK: - ThreadRoomTitleViewDelegate

extension ThreadListViewController: ThreadRoomTitleViewDelegate {
    
    func threadRoomTitleViewDidTapOptions(_ view: ThreadRoomTitleView) {
        self.viewModel.process(viewAction: .showFilterTypes)
    }
    
}
