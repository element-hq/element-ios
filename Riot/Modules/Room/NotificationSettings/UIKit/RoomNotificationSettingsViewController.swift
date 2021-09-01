// File created from ScreenTemplate
// $ createScreen.sh Room/NotificationSettings RoomNotificationSettings
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

final class RoomNotificationSettingsViewController: UIViewController {
     
    // MARK: - Properties
    
    private enum Constants {
        static let linkToAccountSettings = "linkToAccountSettings"
    }
    
    // MARK: Outlets

    @IBOutlet private weak var mainTableView: UITableView!
    
    // MARK: Private

    private var viewModel: RoomNotificationSettingsViewModelType!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    private lazy var avatarView: RoomNotificationSettingsAvatarView = {
        RoomNotificationSettingsAvatarView.loadFromNib()
    }()

    private struct Row {
        var cellViewData: RoomNotificationSettingsCellViewData
        var action: (() -> Void)?
    }

    private struct Section {
        var title: String
        var rows: [Row]
        var footerState: RoomNotificationSettingsFooter.State
    }

    private var sections: [Section] = [] {
        didSet {
            mainTableView.reloadData()
        }
    }
    
    private var viewState: RoomNotificationSettingsViewStateType!
    
    // MARK: - Setup
    
    class func instantiate(with viewModel: RoomNotificationSettingsViewModelType) -> RoomNotificationSettingsViewController {
        let viewController = StoryboardScene.RoomNotificationSettingsViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        setupViews()
        activityPresenter = ActivityIndicatorPresenter()
        errorPresenter = MXKErrorAlertPresentation()
        
        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
        
        viewModel.viewDelegate = self
        viewModel.process(viewAction: .load)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        view.backgroundColor = theme.headerBackgroundColor
        mainTableView.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        mainTableView.reloadData()
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        
        self.title = VectorL10n.roomDetailsNotifs
        let doneBarButtonItem = MXKBarButtonItem(title: VectorL10n.roomNotifsSettingsDoneAction, style: .plain) { [weak self] in
            self?.viewModel.process(viewAction: .save)
        }
        
        let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.roomNotifsSettingsCancelAction, style: .plain) { [weak self] in
            self?.viewModel.process(viewAction: .cancel)
        }
        
        if navigationController?.navigationBar.backItem == nil {
            navigationItem.leftBarButtonItem = cancelBarButtonItem
        }
        navigationItem.rightBarButtonItem = doneBarButtonItem
        mainTableView.register(cellType: RoomNotificationSettingsCell.self)
        mainTableView.register(headerFooterViewType: RoomNotificationSettingsFooter.self)
        mainTableView.register(headerFooterViewType: TitleHeaderView.self)
        mainTableView.sectionFooterHeight = UITableView.automaticDimension
        mainTableView.sectionHeaderHeight = UITableView.automaticDimension
        mainTableView.estimatedSectionFooterHeight = 50
        mainTableView.estimatedSectionHeaderHeight = 30
    }
    
    private func render(viewState: RoomNotificationSettingsViewStateType) {
        
        if viewState.saving {
            activityPresenter.presentActivityIndicator(on: view, animated: true)
        } else {
            activityPresenter.removeCurrentActivityIndicator(animated: true)
        }
        self.viewState = viewState
        if let avatarData = viewState.avatarData as? AvatarViewDataProtocol {
            mainTableView.tableHeaderView = avatarView
            avatarView.configure(viewData: avatarData)
            avatarView.update(theme: theme)
        }
        updateSections()
    }
    
    private func updateSections() {
        let rows = viewState.notificationOptions.map({ (setting) -> Row in
            let cellViewData = RoomNotificationSettingsCellViewData(notificicationState: setting, selected: viewState.notificationState == setting)
            return Row(cellViewData: cellViewData,
                       action: {
                        self.viewModel.process(viewAction: .selectNotificationState(setting))
            })
        })
        let footerState = RoomNotificationSettingsFooter.State(showEncryptedNotice: viewState.roomEncrypted, showAccountLink: false)
        let section0 = Section(title: VectorL10n.roomNotifsSettingsNotifyMeFor, rows: rows, footerState: footerState)
        sections = [
            section0
        ]
    }
}

// MARK: - UITableViewDataSource
extension RoomNotificationSettingsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        let cell: RoomNotificationSettingsCell = tableView.dequeueReusableCell(for: indexPath)
        cell.update(state: row.cellViewData)
        cell.update(theme: theme)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

}

// MARK: - UITableViewDelegate
extension RoomNotificationSettingsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView: TitleHeaderView = tableView.dequeueReusableHeaderFooterView() else { return nil }
        headerView.update(title: sections[section].title)
        headerView.update(theme: theme)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footerView: RoomNotificationSettingsFooter = tableView.dequeueReusableHeaderFooterView() else { return nil }
        let footerState = sections[section].footerState
        footerView.update(footerState: footerState)
        footerView.update(theme: theme)
        return footerView
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let row = sections[indexPath.section].rows[indexPath.row]
        row.action?()
    }
    
}

// MARK: - RoomNotificationSettingsViewModelViewDelegate
extension RoomNotificationSettingsViewController: RoomNotificationSettingsViewModelViewDelegate {

    func roomNotificationSettingsViewModel(_ viewModel: RoomNotificationSettingsViewModelType, didUpdateViewState viewSate: RoomNotificationSettingsViewStateType) {
        render(viewState: viewSate)
    }
}
