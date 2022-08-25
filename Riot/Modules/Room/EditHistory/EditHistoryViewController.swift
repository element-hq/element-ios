// File created from ScreenTemplate
// $ createScreen.sh Room/EditHistory EditHistory
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

import Reusable
import UIKit

final class EditHistoryViewController: UIViewController {
    // MARK: - Constants
    
    private enum Constants {
        static let estimatedRowHeight: CGFloat = 38.0
        static let estimatedSectionHeaderHeight: CGFloat = 28.0
        static let editHistoryMessageTimeFormat = "HH:mm"
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private var tableView: UITableView!
    
    // MARK: Private

    private var viewModel: EditHistoryViewModelType!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityIndicatorPresenter: ActivityIndicatorPresenter!
    
    private var editHistorySections: [EditHistorySection] = []
    
    private lazy var sectionDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .none
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter
    }()
    
    private lazy var messageDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Constants.editHistoryMessageTimeFormat
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter
    }()

    // MARK: - Setup
    
    class func instantiate(with viewModel: EditHistoryViewModelType) -> EditHistoryViewController {
        let viewController = StoryboardScene.EditHistoryViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        title = VectorL10n.roomMessageEditsHistoryTitle
        
        setupViews()
        activityIndicatorPresenter = ActivityIndicatorPresenter()
        errorPresenter = MXKErrorAlertPresentation()
        
        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
        
        viewModel.viewDelegate = self

        viewModel.process(viewAction: .loadMore)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        view.backgroundColor = theme.backgroundColor
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
    
    private func setupViews() {
        let closeBarButtonItem = MXKBarButtonItem(title: VectorL10n.close, style: .plain) { [weak self] in
            self?.closeButtonAction()
        }
        
        navigationItem.rightBarButtonItem = closeBarButtonItem
        
        setupTableView()
    }
    
    private func setupTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Constants.estimatedRowHeight
        tableView.register(cellType: EditHistoryCell.self)
        
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = Constants.estimatedSectionHeaderHeight
        tableView.register(headerFooterViewType: EditHistoryHeaderView.self)
        
        tableView.tableFooterView = UIView()
    }

    private func render(viewState: EditHistoryViewState) {
        switch viewState {
        case .loading:
            renderLoading()
        case .loaded(let sections, let addedCount, let allDataLoaded):
            renderLoaded(sections: sections, addedCount: addedCount, allDataLoaded: allDataLoaded)
        case .error(let error):
            render(error: error)
        }
    }
    
    private func renderLoading() {
        activityIndicatorPresenter.presentActivityIndicator(on: view, animated: true)
    }
    
    private func renderLoaded(sections: [EditHistorySection], addedCount: Int, allDataLoaded: Bool) {
        activityIndicatorPresenter.removeCurrentActivityIndicator(animated: true)
        editHistorySections = sections
        tableView.reloadData()
    }
    
    private func render(error: Error) {
        activityIndicatorPresenter.removeCurrentActivityIndicator(animated: true)
        errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }
    
    // MARK: - Actions

    private func closeButtonAction() {
        viewModel.process(viewAction: .close)
    }
}

// MARK: - UITableViewDataSource

extension EditHistoryViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        editHistorySections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        editHistorySections[section].messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let editHistoryCell = tableView.dequeueReusableCell(for: indexPath, cellType: EditHistoryCell.self)
        
        let editHistoryMessage = editHistorySections[indexPath.section].messages[indexPath.row]
        
        let timeString = messageDateFormatter.string(from: editHistoryMessage.date)
        
        editHistoryCell.update(theme: theme)
        editHistoryCell.fill(with: timeString, and: editHistoryMessage.message)
        
        return editHistoryCell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let editHistoryHeaderView: EditHistoryHeaderView = tableView.dequeueReusableHeaderFooterView() else {
            return nil
        }
        let editHistorySection = editHistorySections[section]
        let dateString = sectionDateFormatter.string(from: editHistorySection.date)
        
        editHistoryHeaderView.update(theme: theme)
        editHistoryHeaderView.fill(with: dateString)
        return editHistoryHeaderView
    }
}

// MARK: - UITableViewDelegate

extension EditHistoryViewController: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Check if a scroll beyond scroll view content occurs
        let distanceFromBottom = scrollView.contentSize.height - scrollView.contentOffset.y
        if distanceFromBottom < scrollView.frame.size.height {
            viewModel.process(viewAction: .loadMore)
        }
    }
}

// MARK: - EditHistoryViewModelViewDelegate

extension EditHistoryViewController: EditHistoryViewModelViewDelegate {
    func editHistoryViewModel(_ viewModel: EditHistoryViewModelType, didUpdateViewState viewSate: EditHistoryViewState) {
        render(viewState: viewSate)
    }
}
