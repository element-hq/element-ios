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
    
}

final class RoomNotificationSettingsNotifyViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var mainTableView: UITableView!
    
    // MARK: Private
    
    private var theme: Theme!
    private var mxRoom: MXRoom!
    private let plainStyleCellReuseIdentifier = "plain"
    private let linkToAccountSettings = "linkToAccountSettings"
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    
    private enum RowType {
        case plain
    }
    
    private struct Row {
        var type: RowType
        var setting: RoomNotificationSetting
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
        let rows = RoomNotificationSetting.allCases.map({ (setting) -> Row in
            return Row(type: .plain,
                       setting: setting,
                       text: setting.longTitle,
                       accessoryType: mxRoom.notifySettingForNotifications == setting ? .checkmark : .none,
                       action: {
                        self.showActivityIndicator()
                self.mxRoom.updateNotifySetting(to: setting, completion: { (response) in
                    self.hideActivityIndicator()
                    
                    switch response {
                    case .success:
                        self.updateSections()
                    case .failure(let error):
                        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: {
                            
                        })
                    }
                })
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
        footer_0.addAttribute(NSAttributedString.Key.link, value: linkToAccountSettings, range: linkRange)
        let section0 = Section(header: nil, rows: rows, footer: footer_0)
        
        sections = [
            section0
        ]
    }
    
    // MARK: Public
    
    weak var delegate: RoomNotificationSettingsNotifyViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate(withRoom room: MXRoom) -> RoomNotificationSettingsNotifyViewController {
        let viewController = StoryboardScene.RoomNotificationSettingsNotifyViewController.initialScene.instantiate()
        viewController.theme = ThemeService.shared().theme
        viewController.mxRoom = room
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.title = "Notify me with"
        self.vc_removeBackTitle()
        
        self.setupViews()
        self.activityPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = MXKErrorAlertPresentation()
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        updateSections()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func setupViews() {
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

// MARK - UITableViewDataSource

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
        case .plain:
            var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: plainStyleCellReuseIdentifier)
            if cell == nil {
                cell = UITableViewCell(style: .value1, reuseIdentifier: plainStyleCellReuseIdentifier)
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

extension RoomNotificationSettingsNotifyViewController: RiotTableViewHeaderFooterViewDelegate {
    
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
