// File created from ScreenTemplate
// $ createScreen.sh Room/NotificationSettings RoomNotificationSettings
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

final class RoomNotificationSettingsViewController: UIViewController {
     
    // MARK: - Properties
    private enum Constants {
        static let plainStyleCellReuseIdentifier = "plain"
        static let linkToAccountSettings = "linkToAccountSettings"
    }
    // MARK: Outlets

    @IBOutlet private weak var mainTableView: UITableView!
    
    // MARK: Private

    private var viewModel: RoomNotificationSettingsViewModelType!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!

    private enum RowType {
        case plain
    }

    private struct Row {
        var type: RowType
        var setting: RoomNotificationState
        var text: String?
        var accessoryType: UITableViewCell.AccessoryType = .none
        var action: (() -> Void)?
    }

    private struct Section {
        var header: String?
        var rows: [Row]
        var footer: NSAttributedString?
    }

    private var sections: [Section] = [] {
        didSet {
            mainTableView.reloadData()
        }
    }
    
    private var viewState: RoomNotificationSettingsViewState!
    
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
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        let doneBarButtonItem = MXKBarButtonItem(title: "Done", style: .plain) { [weak self] in
            self?.viewModel.process(viewAction: .save)
        }
        
        let cancelBarButtonItem = MXKBarButtonItem(title: "Cancel", style: .plain) { [weak self] in
            self?.viewModel.process(viewAction: .cancel)
        }
        
        if navigationController?.navigationBar.backItem == nil {
            navigationItem.leftBarButtonItem = cancelBarButtonItem
        }
        navigationItem.rightBarButtonItem = doneBarButtonItem
    }
    
    private func render(viewState: RoomNotificationSettingsViewState) {
        
        if viewState.saving {
            activityPresenter.presentActivityIndicator(on: view, animated: true)
        } else {
            activityPresenter.removeCurrentActivityIndicator(animated: true)
        }
        self.viewState = viewState
        updateSections()
    }
    
    private func updateSections() {
        let rows = RoomNotificationState.allCases.map({ (setting) -> Row in
            return Row(type: .plain,
                       setting: setting,
                       text: setting.title,
                       accessoryType: viewState.notificationState == setting ? .checkmark : .none,
                       action: {
                        self.viewModel.process(viewAction: .selectNotificationState(setting))
            })
        })

        let formatStr = "You can manage keywords in the %@"
        let linkStr = "Account Settings"
        let formattedStr = String(format: formatStr, arguments: [linkStr])

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.16
        let footer_0 = NSMutableAttributedString(string: formattedStr, attributes: [
            NSAttributedString.Key.kern: -0.08,
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13.0)
            ])
        let linkRange = (footer_0.string as NSString).range(of: linkStr)
        footer_0.addAttribute(NSAttributedString.Key.link, value: Constants.linkToAccountSettings, range: linkRange)
        let section0 = Section(header: nil, rows: rows, footer: footer_0)

        sections = [
            section0
        ]
    }
}

// MARK - UITableViewDataSource
extension RoomNotificationSettingsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]

        switch row.type {
        case .plain:
            var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: Constants.plainStyleCellReuseIdentifier)
            if cell == nil {
                cell = UITableViewCell(style: .value1, reuseIdentifier: Constants.plainStyleCellReuseIdentifier)
            }
            cell.textLabel?.font = .systemFont(ofSize: 17)
            cell.detailTextLabel?.font = .systemFont(ofSize: 16)
            cell.textLabel?.text = row.text
            if row.accessoryType == .checkmark {
                cell.accessoryView = UIImageView(image: Asset.Images.checkmark.image)
            } else {
                cell.accessoryView = nil
                cell.accessoryType = row.accessoryType
            }
            cell.textLabel?.textColor = theme.textPrimaryColor
            cell.detailTextLabel?.textColor = theme.textSecondaryColor
            cell.backgroundColor = theme.backgroundColor
            cell.contentView.backgroundColor = .clear
            cell.tintColor = theme.tintColor
            return cell
        }
    }

}

// MARK - UITableViewDelegate
extension RoomNotificationSettingsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = theme.backgroundColor
        cell.selectedBackgroundView = UIView()
        cell.selectedBackgroundView?.backgroundColor = theme.selectedBackgroundColor
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].header
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sections[section].footer?.string
    }

//    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
//        if sections[section].footer == nil {
//            return nil
//        }
//
//        let view = tableView.dequeueReusableHeaderFooterView(RiotTableViewHeaderFooterView.self)
//
//        view?.textView.attributedText = sections[section].footer
//        view?.update(theme: theme)
//        view?.delegate = self
//
//        return view
//    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let row = sections[indexPath.section].rows[indexPath.row]
        row.action?()
    }

}

// MARK: - RoomNotificationSettingsViewModelViewDelegate
extension RoomNotificationSettingsViewController: RoomNotificationSettingsViewModelViewDelegate {

    func roomNotificationSettingsViewModel(_ viewModel: RoomNotificationSettingsViewModelType, didUpdateViewState viewSate: RoomNotificationSettingsViewState) {
        render(viewState: viewSate)
    }
}

extension RoomNotificationState {
    var title: String {
        switch self {
        case .all:
            return "All Messages"
        case .mentionsOnly:
            return "Mentions and Keywords only"
        case .mute:
            return "None"
        }
    }
}
