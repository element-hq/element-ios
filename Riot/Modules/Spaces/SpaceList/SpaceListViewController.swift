// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceList SpaceList
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

final class SpaceListViewController: UIViewController {
    // MARK: - Constants
    
    private enum Constants {
        static let estimatedRowHeight: CGFloat = 46.0
    }
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet var tableView: UITableView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    // MARK: Private

    private var viewModel: SpaceListViewModelType!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    
    private var sections: [SpaceListSection] = []

    // MARK: - Setup
    
    class func instantiate(with viewModel: SpaceListViewModelType) -> SpaceListViewController {
        let viewController = StoryboardScene.SpaceListViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        setupViews()
        errorPresenter = MXKErrorAlertPresentation()
        
        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
        
        viewModel.viewDelegate = self

        viewModel.process(viewAction: .loadData)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        view.backgroundColor = theme.colors.background
        tableView.backgroundColor = theme.colors.background
        
        tableView.reloadData()
        
        titleLabel.textColor = theme.colors.primaryContent
        titleLabel.font = theme.fonts.bodySB
        
        activityIndicator.color = theme.colors.secondaryContent
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        setupTableView()
        titleLabel.text = VectorL10n.spacesLeftPanelTitle
    }
    
    private func setupTableView() {
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Constants.estimatedRowHeight
        tableView.allowsSelection = true
        tableView.register(cellType: SpaceListViewCell.self)
        tableView.tableFooterView = UIView()
    }

    private func render(viewState: SpaceListViewState) {
        switch viewState {
        case .loading:
            renderLoading()
        case .loaded(let sections):
            renderLoaded(sections: sections)
        case .selectionChanged(let indexPath):
            renderSelectionChanged(at: indexPath)
        case .error(let error):
            render(error: error)
        }
    }
    
    private func renderLoading() {
        activityIndicator.startAnimating()
    }
    
    private func renderLoaded(sections: [SpaceListSection]) {
        activityIndicator.stopAnimating()
        self.sections = sections
        tableView.reloadData()
    }
    
    private func renderSelectionChanged(at indexPath: IndexPath) {
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
    }
    
    private func render(error: Error) {
        errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }
}

// MARK: - SpaceListViewModelViewDelegate

extension SpaceListViewController: SpaceListViewModelViewDelegate {
    func spaceListViewModel(_ viewModel: SpaceListViewModelType, didUpdateViewState viewSate: SpaceListViewState) {
        render(viewState: viewSate)
    }
}

// MARK: - UITableViewDataSource

extension SpaceListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberOfRows: Int
        
        let spaceListSection = sections[section]
        
        switch spaceListSection {
        case .home:
            numberOfRows = 1
        case .spaces(let viewDataList):
            numberOfRows = viewDataList.count
        case .addSpace:
            numberOfRows = 1
        }

        return numberOfRows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: SpaceListViewCell.self)
        
        let viewData: SpaceListItemViewData
        
        let spaceListSection = sections[indexPath.section]
        
        switch spaceListSection {
        case .home(let spaceViewData):
            viewData = spaceViewData
        case .spaces(let viewDataList):
            viewData = viewDataList[indexPath.row]
        case .addSpace(let spaceViewData):
            viewData = spaceViewData
        }
        
        cell.update(theme: theme)
        cell.fill(with: viewData)
        cell.selectionStyle = .none
        cell.delegate = self
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension SpaceListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.process(viewAction: .selectRow(at: indexPath, from: tableView.cellForRow(at: indexPath)))
    }
}

// MARK: - SpaceListViewCellDelegate

extension SpaceListViewController: SpaceListViewCellDelegate {
    func spaceListViewCell(_ cell: SpaceListViewCell, didPressMore button: UIButton) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            MXLog.warning("[SpaceListViewController] didPressMore called from invalid cell.")
            return
        }
        viewModel.process(viewAction: .moreAction(at: indexPath, from: button))
    }
}
