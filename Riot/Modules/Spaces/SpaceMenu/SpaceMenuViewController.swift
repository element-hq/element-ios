//
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

class SpaceMenuViewController: UIViewController {
    // MARK: - Constants
    
    private enum Constants {
        static let estimatedRowHeight: CGFloat = 64.0
    }
    
    // MARK: Private

    private var theme: Theme!
    private var session: MXSession!
    private var spaceId: String!
    private var viewModel: SpaceMenuViewModelType!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!

    // MARK: Outlets

    @IBOutlet private var avatarView: SpaceAvatarView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var closeButton: UIButton!
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var bottomMargin: NSLayoutConstraint!

    // MARK: - Setup
    
    class func instantiate(forSpaceWithId spaceId: String, matrixSession: MXSession, viewModel: SpaceMenuViewModelType!) -> SpaceMenuViewController {
        let viewController = StoryboardScene.SpaceMenuViewController.initialScene.instantiate()
        viewController.session = matrixSession
        viewController.spaceId = spaceId
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AnalyticsScreenTracker.trackScreen(.spaceMenu)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        self.theme.statusBarStyle
    }
    
    override var preferredContentSize: CGSize {
        get {
            CGSize(width: 320, height: tableView.frame.minY + Constants.estimatedRowHeight * CGFloat(viewModel.menuItems.count) + bottomMargin.constant)
        }
        set {
            super.preferredContentSize = newValue
        }
    }
    
    // MARK: - IBActions
    
    @IBAction private func closeAction(sender: UIButton) {
        viewModel.process(viewAction: .dismiss)
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        view.backgroundColor = theme.colors.background
        
        titleLabel.textColor = theme.colors.primaryContent
        titleLabel.font = theme.fonts.title3SB
        subtitleLabel.textColor = theme.colors.secondaryContent
        subtitleLabel.font = theme.fonts.caption1
        closeButton.backgroundColor = theme.roomInputTextBorder
        closeButton.tintColor = theme.noticeSecondaryColor
        
        if spaceId == SpaceListViewModel.Constants.homeSpaceId {
            let defaultAsset = ThemeService.shared().isCurrentThemeDark() ? Asset.Images.spaceHomeIconDark : Asset.Images.spaceHomeIconLight
            let avatarViewData = AvatarViewData(matrixItemId: spaceId, displayName: nil, avatarUrl: nil, mediaManager: session.mediaManager, fallbackImage: .image(defaultAsset.image, .center))
            avatarView.fill(with: avatarViewData)
        }
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        setupTableView()
        
        if spaceId == SpaceListViewModel.Constants.homeSpaceId {
            titleLabel.text = VectorL10n.titleHome
            subtitleLabel.text = VectorL10n.settingsTitle
            
            return
        }

        guard let space = session.spaceService.getSpace(withId: spaceId), let summary = space.summary else {
            MXLog.error("[SpaceMenuViewController] setupViews: no space found")
            return
        }
        
        let avatarViewData = AvatarViewData(matrixItemId: summary.roomId, displayName: summary.displayname, avatarUrl: summary.avatar, mediaManager: session.mediaManager, fallbackImage: .matrixItem(summary.roomId, summary.displayname))

        titleLabel.text = space.summary?.displayname
        // TODO: display members instead once done on android
//        self.subtitleLabel.text = space.membersId.count == 1 ? VectorL10n.roomTitleOneMember :
//            VectorL10n.roomTitleMembers("\(space.membersId.count)")
        subtitleLabel.text = summary.topic
        avatarView.fill(with: avatarViewData)
        
        closeButton.layer.masksToBounds = true
        closeButton.layer.cornerRadius = closeButton.bounds.height / 2
    }
    
    private func setupTableView() {
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Constants.estimatedRowHeight
        tableView.allowsSelection = true
        tableView.register(cellType: SpaceMenuListViewCell.self)
        tableView.register(cellType: SpaceMenuSwitchViewCell.self)
        tableView.tableFooterView = UIView()
    }
    
    private func render(viewState: SpaceMenuViewState) {
        switch viewState {
        case .loading:
            renderLoading()
        case .loaded:
            renderLoaded()
        case .leaveOptions(let displayName, let isAdmin):
            renderLeaveOptions(displayName: displayName, isAdmin: isAdmin)
        case .error(let error):
            render(error: error)
        case .deselect:
            renderDeselect()
        }
    }
    
    private func renderLoading() {
        activityPresenter.presentActivityIndicator(on: view, animated: true)
    }
    
    private func renderLoaded() {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        renderDeselect()
    }
    
    private func renderLeaveOptions(displayName: String, isAdmin: Bool) {
        var message = VectorL10n.leaveSpaceMessage(displayName)

        if isAdmin {
            message += "\n\n" + VectorL10n.leaveSpaceMessageAdminWarning
        }

        let alert = UIAlertController(title: VectorL10n.leaveSpaceTitle(displayName), message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: VectorL10n.leaveSpaceOnlyAction, style: .default, handler: { [weak self] _ in
            self?.viewModel.process(viewAction: .leaveSpaceAndKeepRooms)
        }))
        alert.addAction(UIAlertAction(title: VectorL10n.leaveSpaceAndAllRoomsAction, style: .destructive, handler: { [weak self] _ in
            self?.viewModel.process(viewAction: .leaveSpaceAndLeaveRooms)
        }))
        alert.addAction(UIAlertAction(title: VectorL10n.cancel, style: .cancel, handler: { [weak self] _ in
            self?.renderDeselect()
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    private func render(error: Error) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }
    
    private func renderDeselect() {
        if let selectedRow = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedRow, animated: true)
        }
    }
}

// MARK: - SlidingModalPresentable

extension SpaceMenuViewController: SlidingModalPresentable {
    func allowsDismissOnBackgroundTap() -> Bool {
        true
    }
    
    func layoutHeightFittingWidth(_ width: CGFloat) -> CGFloat {
        preferredContentSize.height
    }
}

// MARK: - SpaceMenuViewModelViewDelegate

extension SpaceMenuViewController: SpaceMenuViewModelViewDelegate {
    func spaceMenuViewModel(_ viewModel: SpaceMenuViewModelType, didUpdateViewState viewSate: SpaceMenuViewState) {
        render(viewState: viewSate)
    }
}

// MARK: - UITableViewDataSource

extension SpaceMenuViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.menuItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewData = viewModel.menuItems[indexPath.row]
        
        let cell = viewData.style == .toggle ? tableView.dequeueReusableCell(for: indexPath, cellType: SpaceMenuSwitchViewCell.self) :
            tableView.dequeueReusableCell(for: indexPath, cellType: SpaceMenuListViewCell.self)
        
        if let cell = cell as? SpaceMenuCell {
            cell.update(theme: theme)
            cell.update(with: viewData)
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension SpaceMenuViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.process(viewAction: .selectRow(at: indexPath))
    }
}
