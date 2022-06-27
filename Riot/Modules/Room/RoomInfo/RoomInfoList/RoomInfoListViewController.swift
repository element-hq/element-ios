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
import CommonKit
import MatrixSDK

final class RoomInfoListViewController: UIViewController {
    
    // MARK: - Constants
    
    private enum Constants {
        static let defaultStyleCellReuseIdentifier = "default"
        static let tableViewSectionMinHeight: CGFloat = 8.0
    }
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private weak var mainTableView: UITableView!
    
    // MARK: Private

    private var viewModel: RoomInfoListViewModelType!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol!
    private var loadingIndicator: UserIndicator?
    private var isRoomDirect: Bool = false
    private var screenTracker = AnalyticsScreenTracker(screen: .roomDetails)
    
    private lazy var closeButton: CloseButton = {
        let button = CloseButton()
        button.isHighlighted = true
        button.addTarget(self, action: #selector(closeButtonTapped(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var basicInfoView: RoomInfoBasicView = {
        let view = RoomInfoBasicView.loadFromNib()
        view.onTopicSizeChange = { [weak self] _ in
            self?.view.setNeedsLayout()
        }
        return view
    }()
    
    private lazy var leaveAlertController: UIAlertController = {
        let title = self.isRoomDirect ? VectorL10n.roomParticipantsLeavePromptTitleForDm : VectorL10n.roomParticipantsLeavePromptTitle
        let message = self.isRoomDirect ? VectorL10n.roomParticipantsLeavePromptMsgForDm : VectorL10n.roomParticipantsLeavePromptMsg
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        controller.addAction(UIAlertAction(title: VectorL10n.cancel, style: .cancel, handler: nil))
        controller.addAction(UIAlertAction(title: VectorL10n.leave, style: .default, handler: { [weak self] (action) in
            guard let self = self else { return }
            self.viewModel.process(viewAction: .leave)
        }))
        controller.mxk_setAccessibilityIdentifier("RoomSettingsVCLeaveAlert")
        
        return controller
    }()
    
    private enum RowType {
        case `default`
        case destructive
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
        
        self.indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: self)
    
        self.errorPresenter = MXKErrorAlertPresentation()
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        self.viewModel.viewDelegate = self

        self.viewModel.process(viewAction: .loadData)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        screenTracker.trackScreen()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        mainTableView.vc_relayoutHeaderView()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopLoading()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: {_ in
            self.basicInfoView.updateTrimmingOnTopic()
        }, completion: nil)
    }
    
    // MARK: - Private
    
    private func updateSections(with viewData: RoomInfoListViewData) {
        isRoomDirect = viewData.isDirect
        basicInfoView.configure(withViewData: viewData.basicInfoViewData)
        
        var tmpSections: [Section] = []
        
        let rowSettings = Row(type: .default, icon: Asset.Images.settingsIcon.image, text: VectorL10n.roomDetailsSettings, accessoryType: .disclosureIndicator) {
            self.viewModel.process(viewAction: .navigate(target: .settings()))
        }
        let roomNotifications = Row(type: .default, icon: Asset.Images.notifications.image, text: VectorL10n.roomDetailsNotifs, accessoryType: .disclosureIndicator) {
            self.viewModel.process(viewAction: .navigate(target: .notifications))
        }
        let text = viewData.numberOfMembers == 1 ? VectorL10n.roomInfoListOneMember : VectorL10n.roomInfoListSeveralMembers(String(viewData.numberOfMembers))
        let rowMembers = Row(type: .default, icon: Asset.Images.userIcon.image, text: text, accessoryType: .disclosureIndicator) {
            self.viewModel.process(viewAction: .navigate(target: .members))
        }
        let rowUploads = Row(type: .default, icon: Asset.Images.scrollup.image, text: VectorL10n.roomDetailsFiles, accessoryType: .disclosureIndicator) {
            self.viewModel.process(viewAction: .navigate(target: .uploads))
        }
        let rowSearch = Row(type: .default, icon: Asset.Images.searchIcon.image, text: VectorL10n.roomDetailsSearch, accessoryType: .disclosureIndicator) {
            self.viewModel.process(viewAction: .navigate(target: .search))
        }
        let rowIntegrations = Row(type: .default, icon: Asset.Images.integrationsIcon.image, text: VectorL10n.roomDetailsIntegrations, accessoryType: .disclosureIndicator) {
            self.viewModel.process(viewAction: .navigate(target: .integrations))
        }
        
        var rows = [rowSettings]
        
        if BuildSettings.showNotificationsV2 {
            rows.append(roomNotifications)
        }
        if RiotSettings.shared.roomInfoScreenShowIntegrations {
            rows.append(rowIntegrations)
        }
        rows.append(rowMembers)
        rows.append(rowUploads)
        if !viewData.isEncrypted {
            rows.append(rowSearch)
        }

        let sectionSettings = Section(header: VectorL10n.roomInfoListSectionOther,
                                      rows: rows,
                                      footer: nil)
        
        let leaveTitle = viewData.basicInfoViewData.isDirect ?
            VectorL10n.roomParticipantsLeavePromptTitleForDm :
            VectorL10n.roomParticipantsLeavePromptTitle
        let rowLeave = Row(type: .destructive, icon: Asset.Images.roomActionLeave.image, text: leaveTitle, accessoryType: .none) {
            self.present(self.leaveAlertController, animated: true, completion: nil)
        }
        let sectionLeave = Section(header: nil,
                                   rows: [rowLeave],
                                   footer: nil)
        
        tmpSections.append(sectionSettings)
        tmpSections.append(sectionLeave)
        
        sections = tmpSections
    }
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.headerBackgroundColor
        self.mainTableView.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }

        closeButton.update(theme: theme)
        basicInfoView.update(theme: theme)
        
        mainTableView.reloadData()
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        if navigationController?.viewControllers.count ?? 0 <= 1 {
            self.navigationItem.rightBarButtonItem = MXKBarButtonItem(customView: closeButton)
        }
        
        self.title = ""
        self.vc_removeBackTitle()
        // TODO: Check string with product (+ DM specific alt ?) and move this out of Untranslated.
        self.navigationItem.backButtonTitle = VectorL10n.roomInfoBackButtonTitle

        mainTableView.register(headerFooterViewType: TextViewTableViewHeaderFooterView.self)
        mainTableView.sectionHeaderHeight = UITableView.automaticDimension
        mainTableView.estimatedSectionHeaderHeight = 50
        mainTableView.sectionFooterHeight = UITableView.automaticDimension
        mainTableView.estimatedSectionFooterHeight = 50
        mainTableView.rowHeight = UITableView.automaticDimension
        mainTableView.tableHeaderView = basicInfoView
    }

    private func render(viewState: RoomInfoListViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .loaded(let viewData):
            self.renderLoaded(viewData: viewData)
        case .error(let error):
            self.render(error: error)
        }
    }
    
    private func renderLoading() {
        loadingIndicator = indicatorPresenter.present(
            .loading(
                label: VectorL10n.roomParticipantsLeaveProcessing,
                isInteractionBlocking: true
            )
        )
    }
    
    private func renderLoaded(viewData: RoomInfoListViewData) {
        stopLoading()
        self.updateSections(with: viewData)
    }
    
    private func render(error: Error) {
        stopLoading()
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }
    
    private func stopLoading() {
        loadingIndicator?.cancel()
    }
    
    // MARK: - Actions

    @objc private func closeButtonTapped(_ sender: Any) {
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
        case .default, .destructive:
            var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: Constants.defaultStyleCellReuseIdentifier)
            if cell == nil {
                cell = UITableViewCell(style: .default, reuseIdentifier: Constants.defaultStyleCellReuseIdentifier)
            }
            if let icon = row.icon {
                if row.type == .default {
                    cell.imageView?.image = MXKTools.resize(icon, to: CGSize(width: 20, height: 20))?.vc_tintedImage(usingColor: theme.textSecondaryColor)
                } else if row.type == .destructive {
                    cell.imageView?.image = MXKTools.resize(icon, to: CGSize(width: 20, height: 20))?.vc_tintedImage(usingColor: theme.noticeColor)
                }
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
            if row.type == .default {
                cell.textLabel?.textColor = theme.textPrimaryColor
                cell.detailTextLabel?.textColor = theme.textSecondaryColor
            } else if row.type == .destructive {
                cell.textLabel?.textColor = theme.noticeColor
                cell.detailTextLabel?.textColor = theme.noticeSecondaryColor
            }
            cell.backgroundColor = theme.backgroundColor
            cell.contentView.backgroundColor = .clear
            cell.tintColor = theme.tintColor
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

        let view: TextViewTableViewHeaderFooterView? = tableView.dequeueReusableHeaderFooterView()

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

        let view: TextViewTableViewHeaderFooterView? = tableView.dequeueReusableHeaderFooterView()

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
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if sections[section].header == nil {
            return Constants.tableViewSectionMinHeight
        }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if sections[section].footer == nil {
            return Constants.tableViewSectionMinHeight
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
