// File created from simpleScreenTemplate
// $ createSimpleScreen.sh Room/Settings/Notifications/Notify RoomNotificationSettingsNotify
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

protocol RoomNotificationSettingsNotifyViewControllerDelegate: class {
    func roomNotificationSettingsNotifyViewControllerDidTapSetupAction(_ viewController: RoomNotificationSettingsNotifyViewController)
    func roomNotificationSettingsNotifyViewControllerDidCancel(_ viewController: RoomNotificationSettingsNotifyViewController)
}

final class RoomNotificationSettingsNotifyViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var mainTableView: UITableView!
    
    // MARK: Private
    
    private var theme: Theme!
    private var mxRoom: MXRoom!
    
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
        var footer: String?
    }
    
    private var sections: [Section] = [] {
        didSet {
            mainTableView.reloadData()
        }
    }
    
    private func updateSections() {
        let row_0_0 = Row(type: .withRightValue("All messages"), text: "Notify me with", accessoryType: .disclosureIndicator) {
            
        }
        
        let section0 = Section(header: "General", rows: [row_0_0], footer: nil)
        
        let row_1_0 = Row(type: .withSwitch(true, onValueChanged: { (switch) in
            
        }), text: "Notify me when @room is used", accessoryType: .none) {
            
        }
        
        let row_1_1 = Row(type: .withSwitch(false, onValueChanged: { (switch) in
            
        }), text: "Show number of messages", accessoryType: .none) {
            
        }
        
        let section1 = Section(header: "Appearance & Sound", rows: [row_1_0, row_1_1], footer: nil)
        
        let row_2_0 = Row(type: .withRightValue("All messages"), text: "Play a sound", accessoryType: .disclosureIndicator) {
            
        }
        
        let section2 = Section(header: nil, rows: [row_2_0], footer: nil)
        
        let row_3_0 = Row(type: .withRightValue("Off"), text: "Custom Sounds", accessoryType: .disclosureIndicator) {
            
        }
        
        let section3 = Section(header: "Custom Sounds", rows: [row_3_0], footer: "Set a custom sound for this room. Manage global settings in ...")
        
        sections = [
            section0,
            section1,
            section2,
            section3
        ]
    }
    
    // MARK: Public
    
    weak var delegate: RoomNotificationSettingsNotifyViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate() -> RoomNotificationSettingsNotifyViewController {
        let viewController = StoryboardScene.RoomNotificationSettingsNotifyViewController.initialScene.instantiate()
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.title = "Template"
        self.vc_removeBackTitle()
        
        self.setupViews()
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func setupViews() {
        
    }
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.headerBackgroundColor
        
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
    
    @IBAction private func validateButtonAction(_ sender: Any) {
        self.delegate?.roomNotificationSettingsNotifyViewControllerDidTapSetupAction(self)
    }

    private func cancelButtonAction() {
        self.delegate?.roomNotificationSettingsNotifyViewControllerDidCancel(self)
    }
}


extension RoomNotificationSettingsNotifyViewController: UITableViewDataSource {
    
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "value1", for: indexPath)
            //            let cell = UITableViewCell(style: .value1, reuseIdentifier: "value1")
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
            cell.mxkSwitch.vc_addAction(for: .valueChanged) {
                onValueChanged?(cell.mxkSwitch)
            }
            cell.mxkLabelLeadingConstraint.constant = cell.vc_separatorInset.left
            cell.mxkSwitchTrailingConstraint.constant = 15
            cell.mxkLabel.textColor = theme.textPrimaryColor
            cell.backgroundColor = theme.backgroundColor
            cell.contentView.backgroundColor = .clear
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].header
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sections[section].footer
    }
    
}

extension RoomNotificationSettingsNotifyViewController: UITableViewDelegate {
    
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let row = sections[indexPath.section].rows[indexPath.row]
        row.action?()
    }
    
}
