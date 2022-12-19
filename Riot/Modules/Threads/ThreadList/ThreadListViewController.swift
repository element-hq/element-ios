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
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private weak var threadsTableView: UITableView!
    @IBOutlet private weak var emptyView: ThreadListEmptyView!
    
    // MARK: Private

    private var viewModel: ThreadListViewModelProtocol!
    private var theme: Theme!
    private var keyboardAvoider: KeyboardAvoider?
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    private var titleView: ThreadRoomTitleView!

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
        AnalyticsScreenTracker.trackScreen(.threadList)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.keyboardAvoider?.stopAvoiding()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard let titleView = self.titleView else { return }
        if UIApplication.shared.statusBarOrientation.isPortrait {
            titleView.updateLayout(for: .landscapeLeft)
        } else {
            titleView.updateLayout(for: .portrait)
        }
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }

        emptyView.update(theme: theme)
        emptyView.backgroundColor = theme.colors.background
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
        titleView.configure(withModel: viewModel.titleModel)
        titleView.updateLayout(for: UIApplication.shared.statusBarOrientation)
        self.titleView = titleView
        navigationItem.leftItemsSupplementBackButton = true
        vc_removeBackTitle()
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleView)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: Asset.Images.threadsFilter.image,
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(filterButtonTapped(_:)))
        
        self.threadsTableView.tableFooterView = UIView()
        self.threadsTableView.register(cellType: ThreadTableViewCell.self)
        self.threadsTableView.keyboardDismissMode = .interactive
    }

    private func render(viewState: ThreadListViewState) {
        switch viewState {
        case .idle:
            break
        case .loading:
            renderLoading()
        case .loaded:
            renderLoaded()
        case .empty(let model):
            renderEmptyView(withModel: model)
        case .showingFilterTypes:
            renderShowingFilterTypes()
        case .showingLongPressActions(let index):
            renderShowingLongPressActions(index)
        case .share(let url, let index):
            renderShare(url, index: index)
        case .toastForCopyLink:
            toastForCopyLink()
        case .error(let error):
            render(error: error)
        }
    }
    
    private func renderLoading() {
        emptyView.isHidden = true
        threadsTableView.isHidden = viewModel.numberOfThreads == 0
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
    }
    
    private func renderLoaded() {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        threadsTableView.isHidden = false
        self.threadsTableView.reloadData()
        navigationItem.rightBarButtonItem?.isEnabled = true
        switch viewModel.selectedFilterType {
        case .all:
            navigationItem.rightBarButtonItem?.image = Asset.Images.threadsFilter.image
        case .myThreads:
            navigationItem.rightBarButtonItem?.image = Asset.Images.threadsFilterApplied.image
        }
    }
    
    private func renderEmptyView(withModel model: ThreadListEmptyModel) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        emptyView.configure(withModel: model)
        threadsTableView.isHidden = true
        emptyView.isHidden = false
        navigationItem.rightBarButtonItem?.isEnabled = viewModel.selectedFilterType == .myThreads
        switch viewModel.selectedFilterType {
        case .all:
            navigationItem.rightBarButtonItem = nil
        case .myThreads:
            navigationItem.rightBarButtonItem?.image = Asset.Images.threadsFilterApplied.image
        }
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
    
    private func renderShowingLongPressActions(_ index: Int) {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        controller.addAction(UIAlertAction(title: VectorL10n.roomEventActionViewInRoom,
                                           style: .default,
                                           handler: { [weak self] action in
                                            guard let self = self else { return }
                                            self.viewModel.process(viewAction: .actionViewInRoom)
                                           }))
        
        controller.addAction(UIAlertAction(title: VectorL10n.threadCopyLinkToThread,
                                           style: .default,
                                           handler: { [weak self] action in
                                            guard let self = self else { return }
                                            self.viewModel.process(viewAction: .actionCopyLinkToThread)
                                           }))
        
        controller.addAction(UIAlertAction(title: VectorL10n.roomEventActionShare,
                                           style: .default,
                                           handler: { [weak self] action in
                                            guard let self = self else { return }
                                            self.viewModel.process(viewAction: .actionShare)
                                           }))
        
        controller.addAction(UIAlertAction(title: VectorL10n.cancel,
                                           style: .cancel,
                                           handler: nil))

        if let cell = threadsTableView.cellForRow(at: IndexPath(row: index, section: 0)) {
            controller.popoverPresentationController?.sourceView = cell
        } else {
            controller.popoverPresentationController?.sourceView = view
        }

        self.present(controller, animated: true, completion: nil)
    }
    
    private func renderShare(_ url: URL, index: Int) {
        let activityVC = UIActivityViewController(activityItems: [url],
                                                  applicationActivities: nil)
        activityVC.modalTransitionStyle = .coverVertical
        if let cell = threadsTableView.cellForRow(at: IndexPath(row: index, section: 0)) {
            activityVC.popoverPresentationController?.sourceView = cell
        } else {
            activityVC.popoverPresentationController?.sourceView = view
        }
        present(activityVC, animated: true, completion: nil)
    }
    
    private func toastForCopyLink() {
        view.vc_toast(message: VectorL10n.roomEventCopyLinkInfo,
                      image: Asset.Images.linkIcon.image)
    }
    
    private func render(error: Error) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }

    // MARK: - Actions
    
    @objc
    private func filterButtonTapped(_ sender: UIBarButtonItem) {
        self.viewModel.process(viewAction: .showFilterTypes)

        Analytics.shared.trackInteraction(.threadListFilterItem)
    }
    
    @IBAction private func longPressed(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else {
            return
        }
        let point = sender.location(in: threadsTableView)
        guard let indexPath = threadsTableView.indexPathForRow(at: point) else {
            return
        }
        guard let cell = threadsTableView.cellForRow(at: indexPath) else {
            return
        }
        if cell.isHighlighted {
            viewModel.process(viewAction: .longPressThread(indexPath.row))
        }
    }

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
        
        cell.update(theme: theme)
        if let threadModel = viewModel.threadModel(at: indexPath.row) {
            cell.configure(withModel: threadModel)
        }
        
        return cell
    }
    
}

//  MARK: - UITableViewDelegate

extension ThreadListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = theme.backgroundColor
        cell.selectedBackgroundView = UIView()
        cell.selectedBackgroundView?.backgroundColor = theme.selectedBackgroundColor
        
        if indexPath.row == viewModel.numberOfThreads - 1 {
            viewModel.process(viewAction: .loadData)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        viewModel.process(viewAction: .selectThread(indexPath.row))

        Analytics.shared.trackInteraction(.threadListThreadItem)
    }
    
}

//  MARK: - ThreadListEmptyViewDelegate

extension ThreadListViewController: ThreadListEmptyViewDelegate {
    
    func threadListEmptyViewTappedShowAllThreads(_ emptyView: ThreadListEmptyView) {
        viewModel.process(viewAction: .selectFilterType(.all))
    }
    
}
