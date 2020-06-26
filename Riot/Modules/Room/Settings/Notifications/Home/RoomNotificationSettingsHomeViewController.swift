// File created from simpleScreenTemplate
// $ createSimpleScreen.sh Room/Settings/Notifications/Home RoomNotificationSettingsHome
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
import Reusable

protocol RoomNotificationSettingsHomeViewControllerDelegate: class {
    
}

final class RoomNotificationSettingsHomeViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var mainTableView: UITableView!
    
    // MARK: Private
    
    private var theme: Theme!
    private var mxRoom: MXRoom!
    private let value1StyleCellReuseIdentifier = "value1"
    private let linkToAccountSettings = "linkToAccountSettings"
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    
    private enum RowType {
        case withRightValue(_ value: String?)
        case withSwitch(_ isOn: Bool, onValueChanged: ((UISwitch) -> Void)?)
    }
    
    private struct Row {
        var type: RowType
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
    
    private func showActivityIndicator() {
        if self.activityPresenter.isPresenting == false {
            self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
        }
    }
    
    private func hideActivityIndicator() {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
    }
    
    private func updateSections() {
        let row_0_0 = Row(type: .withRightValue(mxRoom.notifySettingForNotifications.shortTitle), text: "Notify me with", accessoryType: .disclosureIndicator) { [weak self] in
            guard let self = self else { return }
            let controller = RoomNotificationSettingsNotifyViewController.instantiate(withRoom: self.mxRoom)
            self.navigationController?.pushViewController(controller, animated: true)
        }
        
        let section0 = Section(header: "General", rows: [row_0_0], footer: nil)
        
        let row_1_0 = Row(type: .withSwitch(mxRoom.notifyOnRoomMentions, onValueChanged: { [weak self] (_switch) in
            guard let self = self else { return }
            self.showActivityIndicator()
            self.mxRoom.updateNotifyOnRoomMentionsSetting(to: _switch.isOn, completion: { (response) in
                self.hideActivityIndicator()
                self.updateSections()
                
                switch response {
                case .success:
                    break
                case .failure(let error):
                    self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: {
                        
                    })
                }
            })
        }), text: "Notify me when @room is used", accessoryType: .none) {
            
        }
        
        let row_1_1 = Row(type: .withSwitch(mxRoom.showNumberOfMessages, onValueChanged: { [weak self] (_switch) in
            guard let self = self else { return }
            self.showActivityIndicator()
            self.mxRoom.updateShowNumberOfMessagesSetting(to: _switch.isOn, completion: { (response) in
                self.hideActivityIndicator()
                self.updateSections()
                
                switch response {
                case .success:
                    break
                case .failure(let error):
                    self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: {
                        
                    })
                }
            })
        }), text: "Show number of messages", accessoryType: .none) {
            
        }
        
        let section1 = Section(header: "Appearance & Sound", rows: [row_1_0, row_1_1], footer: nil)
        
        let row_2_0 = Row(type: .withRightValue(mxRoom.soundSettingForNotifications.shortTitle), text: "Play a sound", accessoryType: .disclosureIndicator) { [weak self] in
            guard let self = self else { return }
            let controller = RoomNotificationSettingsSoundViewController.instantiate(withRoom: self.mxRoom)
            self.navigationController?.pushViewController(controller, animated: true)
        }
        
        let section2 = Section(header: nil, rows: [row_2_0], footer: nil)
        
        let row_3_0 = Row(type: .withRightValue("Off"), text: "Custom Sounds", accessoryType: .disclosureIndicator) {
            
        }
        
        let formatStr = "Set a custom sound for this room. Manage global settings in the %@"
        let linkStr = "Account Settings"
        let formattedStr = String(format: formatStr, arguments: [linkStr])
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.16
        let footer_3 = NSMutableAttributedString(string: formattedStr, attributes: [
            NSAttributedString.Key.kern: -0.08,
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13.0)
            ])
        let linkRange = (footer_3.string as NSString).range(of: linkStr)
        footer_3.addAttribute(NSAttributedString.Key.link, value: linkToAccountSettings, range: linkRange)
        let section3 = Section(header: "Custom Sounds", rows: [row_3_0], footer: footer_3)
        
        sections = [
            section0,
            section1,
            section2,
            section3
        ]
    }
    
    // MARK: Public
    
    weak var delegate: RoomNotificationSettingsHomeViewControllerDelegate?
    
    // MARK: - Setup
    
    @objc class func instantiate(withRoom room: MXRoom) -> RoomNotificationSettingsHomeViewController {
        let viewController = StoryboardScene.RoomNotificationSettingsHomeViewController.initialScene.instantiate()
        viewController.theme = ThemeService.shared().theme
        viewController.mxRoom = room
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.title = VectorL10n.roomNotificationSettingsHomeTitle
        self.vc_removeBackTitle()
        
        self.setupViews()
        self.activityPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = MXKErrorAlertPresentation()
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateSections()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func setupViews() {
        mainTableView.register(cellType: MXKTableViewCellWithLabelAndSwitch.self)
        mainTableView.register(headerFooterViewType: RiotTableViewHeaderFooterView.self)
        mainTableView.sectionFooterHeight = UITableView.automaticDimension
        mainTableView.estimatedSectionFooterHeight = 50
    }
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.headerBackgroundColor
        self.mainTableView.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }

    // MARK: - Actions
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
}

// MARK: - UITableViewDataSource

extension RoomNotificationSettingsHomeViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        
        switch row.type {
        case .withRightValue(let rightValue):
            var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: value1StyleCellReuseIdentifier)
            if cell == nil {
                cell = UITableViewCell(style: .value1, reuseIdentifier: value1StyleCellReuseIdentifier)
            }
            cell.textLabel?.font = .systemFont(ofSize: 17)
            cell.detailTextLabel?.font = .systemFont(ofSize: 16)
            cell.textLabel?.text = row.text
            cell.detailTextLabel?.text = rightValue
            cell.accessoryType = row.accessoryType
            cell.textLabel?.textColor = theme.textPrimaryColor
            cell.detailTextLabel?.textColor = theme.textSecondaryColor
            cell.backgroundColor = theme.backgroundColor
            cell.contentView.backgroundColor = .clear
            return cell
        case .withSwitch(let isOn, let onValueChanged):
            let cell: MXKTableViewCellWithLabelAndSwitch = tableView.dequeueReusableCell(for: indexPath)
            cell.mxkLabel.font = .systemFont(ofSize: 17)
            cell.mxkLabel.text = row.text
            cell.mxkSwitch.isOn = isOn
            cell.mxkSwitch.removeTarget(nil, action: nil, for: .valueChanged)
            cell.mxkSwitch.vc_addAction(for: .valueChanged) {
                onValueChanged?(cell.mxkSwitch)
            }
            cell.mxkLabelLeadingConstraint.constant = cell.vc_separatorInset.left
            cell.mxkSwitchTrailingConstraint.constant = 15
            cell.update(theme: theme)
            
            return cell
        }
    }
    
}

// MARK: - UITableViewDelegate

extension RoomNotificationSettingsHomeViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = theme.backgroundColor
        
        if let selectedBackgroundColor = theme.selectedBackgroundColor {
            cell.selectedBackgroundView = UIView()
            cell.selectedBackgroundView?.backgroundColor = selectedBackgroundColor
        } else {
            if tableView.style == .plain {
                cell.selectedBackgroundView = nil
            } else {
                cell.selectedBackgroundView?.backgroundColor = nil
            }
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].header
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sections[section].footer?.string
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if sections[section].footer == nil {
            return nil
        }
        
        let view = tableView.dequeueReusableHeaderFooterView(RiotTableViewHeaderFooterView.self)
        
        view?.textView.attributedText = sections[section].footer
        view?.update(theme: theme)
        view?.delegate = self
        
        return view
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let row = sections[indexPath.section].rows[indexPath.row]
        row.action?()
    }
    
}

// MARK - RiotTableViewHeaderFooterViewDelegate

extension RoomNotificationSettingsHomeViewController: RiotTableViewHeaderFooterViewDelegate {
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if interaction == .invokeDefaultAction {
            if URL.absoluteString == linkToAccountSettings {
                let alert = UIAlertController(title: "Info", message: "Will go to Account Settings", preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                
                self.present(alert, animated: true)
                return true
            }
            return false
        }
        return false
    }
    
}
