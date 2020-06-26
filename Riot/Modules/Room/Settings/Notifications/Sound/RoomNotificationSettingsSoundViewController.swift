// File created from simpleScreenTemplate
// $ createSimpleScreen.sh Room/Settings/Notifications/Sound RoomNotificationSettingsSound
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

protocol RoomNotificationSettingsSoundViewControllerDelegate: class {
    
}

final class RoomNotificationSettingsSoundViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var mainTableView: UITableView!
    
    // MARK: Private
    
    private var theme: Theme!
    private var mxRoom: MXRoom!
    private let plainStyleCellReuseIdentifier = "plain"
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
                       accessoryType: mxRoom.soundSettingForNotifications == setting ? .checkmark : .none,
                       action: {
                        self.showActivityIndicator()
                        self.mxRoom.updateSoundSetting(to: setting, completion: { (response) in
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
        
        let section0 = Section(header: nil, rows: rows, footer: nil)
        
        sections = [
            section0
        ]
    }
    
    // MARK: Public
    
    weak var delegate: RoomNotificationSettingsSoundViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate(withRoom room: MXRoom) -> RoomNotificationSettingsSoundViewController {
        let viewController = StoryboardScene.RoomNotificationSettingsSoundViewController.initialScene.instantiate()
        viewController.theme = ThemeService.shared().theme
        viewController.mxRoom = room
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.title = "Play a sound"
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

extension RoomNotificationSettingsSoundViewController: UITableViewDataSource {
    
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

extension RoomNotificationSettingsSoundViewController: UITableViewDelegate {
    
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
