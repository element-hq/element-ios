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

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
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
        
        self.setupViews()
        self.errorPresenter = MXKErrorAlertPresentation()
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        self.viewModel.viewDelegate = self

        self.viewModel.process(viewAction: .loadData)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.colors.background
        self.tableView.backgroundColor = theme.colors.background
        
        self.tableView.reloadData()
        
        self.titleLabel.textColor = theme.colors.primaryContent
        self.titleLabel.font = theme.fonts.bodySB
        
        self.activityIndicator.color = theme.colors.secondaryContent
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        self.setupTableView()
        self.titleLabel.text = VectorL10n.spacesLeftPanelTitle
    }
    
    private func setupTableView() {
        self.tableView.separatorStyle = .none
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = Constants.estimatedRowHeight
        self.tableView.allowsSelection = true
        self.tableView.register(cellType: SpaceListViewCell.self)
        self.tableView.tableFooterView = UIView()
    }

    private func render(viewState: SpaceListViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .loaded(let sections):
            self.renderLoaded(sections: sections)
        case .selectionChanged(let indexPath):
            self.renderSelectionChanged(at: indexPath)
        case .error(let error):
            self.render(error: error)
        }
    }
    
    private func renderLoading() {
        self.activityIndicator.startAnimating()
    }
    
    private func renderLoaded(sections: [SpaceListSection]) {
        self.activityIndicator.stopAnimating()
        self.sections = sections
        self.tableView.reloadData()
    }
    
    private func renderSelectionChanged(at indexPath: IndexPath) {
        self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
    }
    
    private func render(error: Error) {
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }
}


// MARK: - SpaceListViewModelViewDelegate
extension SpaceListViewController: SpaceListViewModelViewDelegate {
    func spaceListViewModel(_ viewModel: SpaceListViewModelType, didUpdateViewState viewSate: SpaceListViewState) {
        self.render(viewState: viewSate)
    }
}

// MARK: - UITableViewDataSource
extension SpaceListViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let numberOfRows: Int
        
        let spaceListSection = self.sections[section]
        
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
        
        let spaceListSection = self.sections[indexPath.section]
        
        switch spaceListSection {
        case .home(let spaceViewData):
            viewData = spaceViewData
        case .spaces(let viewDataList):
            viewData = viewDataList[indexPath.row]
        case .addSpace(let spaceViewData):
            viewData = spaceViewData
        }
        
        cell.update(theme: self.theme)
        cell.fill(with: viewData)
        cell.selectionStyle = .none
        cell.delegate = self
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension SpaceListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.viewModel.process(viewAction: .selectRow(at: indexPath, from: tableView.cellForRow(at: indexPath)))
    }
}

// MARK: - SpaceListViewCellDelegate
extension SpaceListViewController: SpaceListViewCellDelegate {

    func spaceListViewCell(_ cell: SpaceListViewCell, didPressMore button: UIButton) {
        guard let indexPath = self.tableView.indexPath(for: cell) else {
            MXLog.warning("[SpaceListViewController] didPressMore called from invalid cell.")
            return
        }
        self.viewModel.process(viewAction: .moreAction(at: indexPath, from: button))
    }
}
