// File created from ScreenTemplate
// $ createScreen.sh Room2/RoomInfo RoomInfoList
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

final class RoomInfoListViewController: UIViewController {
    
    // MARK: - Constants
    
    private enum Constants {
        static let defaultStyleCellReuseIdentifier = "default"
    }
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private weak var mainTableView: UITableView!
    
    // MARK: Private

    private var viewModel: RoomInfoListViewModelType!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    
    private lazy var closeButton: UIButton = {
        return UIButton()
    }()
    
    private enum RowType {
        case `default`
        case basicInfo
        case textView
    }
    
    private struct Row {
        var type: RowType
        var icon: UIImage?
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

    // MARK: - Setup
    
    class func instantiate(with viewModel: RoomInfoListViewModelType) -> RoomInfoListViewController {
        let viewController = StoryboardScene.RoomInfoListViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.setupViews()
        self.activityPresenter = ActivityIndicatorPresenter()
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
    
    private func updateSections() {
        var tmpSections: [Section] = []
        
        let row_0_0 = Row(type: .basicInfo, text: nil, accessoryType: .none, action: nil)
        
        let section0 = Section(header: nil,
                               rows: [row_0_0],
                               footer: nil)
        
        tmpSections.append(section0)
        
        if viewModel.isEncrypted {
            let section1 = Section(header: "Security",
                                   rows: [],
                                   footer: "Messages in this room are end to end encrypted")
            
            tmpSections.append(section1)
        }
        
        let row_2_0 = Row(type: .default, icon: Asset.Images.settingsIcon.image, text: "Settings", accessoryType: .disclosureIndicator) {
            self.viewModel.process(viewAction: .navigate(target: .settings))
        }
        let row_2_2 = Row(type: .default, icon: Asset.Images.userIcon.image, text: "\(viewModel.numberOfMembers) members", accessoryType: .disclosureIndicator) {
            self.viewModel.process(viewAction: .navigate(target: .members))
        }
        let row_2_3 = Row(type: .default, icon: Asset.Images.scrollup.image, text: "Uploads", accessoryType: .disclosureIndicator) {
            self.viewModel.process(viewAction: .navigate(target: .uploads))
        }
        
        let section2 = Section(header: "Other",
                               rows: [row_2_0,
                                      row_2_2,
                                      row_2_3],
                               footer: nil)
        
        let row_3_0 = Row(type: .default, icon: Asset.Images.roomActionLeave.image, text: "Leave Room", accessoryType: .none) {
            //  no-op
        }
        let section3 = Section(header: nil,
                               rows: [row_3_0],
                               footer: nil)
        
        tmpSections.append(section2)
        tmpSections.append(section3)
        
        sections = tmpSections
    }
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.headerBackgroundColor
        self.mainTableView.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }

        self.closeButton.backgroundColor = theme.backgroundColor
        theme.applyStyle(onButton: self.closeButton)
        
        mainTableView.reloadData()
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
//            self?.cancelButtonAction()
        }
        
        self.navigationItem.rightBarButtonItem = cancelBarButtonItem
        
        self.title = ""
        
        mainTableView.register(cellType: TextViewTableViewCell.self)
        mainTableView.register(cellType: RoomInfoBasicTableViewCell.self)
        mainTableView.register(headerFooterViewType: TableViewHeaderFooterView.self)
        mainTableView.sectionHeaderHeight = UITableView.automaticDimension
        mainTableView.estimatedSectionHeaderHeight = 50
        mainTableView.sectionFooterHeight = UITableView.automaticDimension
        mainTableView.estimatedSectionFooterHeight = 50
    }

    private func render(viewState: RoomInfoListViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .loaded:
            self.renderLoaded()
        case .error(let error):
            self.render(error: error)
        }
    }
    
    private func renderLoading() {
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
    }
    
    private func renderLoaded() {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.updateSections()
    }
    
    private func render(error: Error) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }
    
    // MARK: - Actions

    @IBAction private func closeButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .cancel)
    }

}


// MARK: - UITableViewDataSource

extension RoomInfoListViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        
        switch row.type {
        case .default:
            var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: Constants.defaultStyleCellReuseIdentifier)
            if cell == nil {
                cell = UITableViewCell(style: .default, reuseIdentifier: Constants.defaultStyleCellReuseIdentifier)
            }
            if let icon = row.icon {
                cell.imageView?.image = MXKTools.resize(icon, to: CGSize(width: 20, height: 20))?.vc_tintedImage(usingColor: theme.textSecondaryColor)
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
        case .basicInfo:
            let cell: RoomInfoBasicTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.configure(withViewModel: viewModel.basicInfoViewModel)
            cell.selectionStyle = .none
            cell.update(theme: theme)
            
            return cell
        case .textView:
            let cell: TextViewTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.textView.textContainer.lineFragmentPadding = 0
            cell.textView.textAlignment = .center
            cell.textView.contentInset = .zero
            cell.textView.textContainerInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
            cell.textView.font = .systemFont(ofSize: 17)
            cell.textView.text = row.text
            cell.textView.isEditable = false
            cell.textView.isScrollEnabled = false
            cell.textView.backgroundColor = .clear
            cell.selectionStyle = .none
            cell.contentView.backgroundColor = theme.headerBackgroundColor
            cell.update(theme: theme)
            
            return cell

        }
    }
    
}

// MARK: - UITableViewDelegate

extension RoomInfoListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = theme.backgroundColor
        cell.selectedBackgroundView = UIView()
        cell.selectedBackgroundView?.backgroundColor = theme.selectedBackgroundColor
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].header
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sections[section].footer
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = sections[section].header else {
            return nil
        }

        let view: TableViewHeaderFooterView? = tableView.dequeueReusableHeaderFooterView()

        view?.textView.text = header
        view?.textView.font = .systemFont(ofSize: 13)
        view?.textViewInsets = UIEdgeInsets(top: 16, left: 16, bottom: 8, right: 16)
        view?.update(theme: theme)

        return view
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footer = sections[section].footer else {
            return nil
        }

        let view: TableViewHeaderFooterView? = tableView.dequeueReusableHeaderFooterView()

        view?.textView.text = footer
        view?.textView.font = .systemFont(ofSize: 13)
        view?.update(theme: theme)

        return view
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let row = sections[indexPath.section].rows[indexPath.row]
        row.action?()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = sections[indexPath.section].rows[indexPath.row]
        
        switch row.type {
        default:
            return UITableView.automaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if sections[section].header == nil {
            return 18
        }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if sections[section].footer == nil {
            return 18
        }
        return UITableView.automaticDimension
    }
    
}

// MARK: - RoomInfoListViewModelViewDelegate

extension RoomInfoListViewController: RoomInfoListViewModelViewDelegate {

    func roomInfoListViewModel(_ viewModel: RoomInfoListViewModelType, didUpdateViewState viewSate: RoomInfoListViewState) {
        self.render(viewState: viewSate)
    }
    
}
