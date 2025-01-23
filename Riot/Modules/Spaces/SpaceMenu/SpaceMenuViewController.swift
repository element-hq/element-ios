// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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

    @IBOutlet private weak var avatarView: SpaceAvatarView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var bottomMargin: NSLayoutConstraint!

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
        
        self.setupViews()
        self.activityPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = MXKErrorAlertPresentation()

        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        self.viewModel.viewDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AnalyticsScreenTracker.trackScreen(.spaceMenu)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    override var preferredContentSize: CGSize {
        get {
            return CGSize(width: 320, height: self.tableView.frame.minY + Constants.estimatedRowHeight * CGFloat(self.viewModel.menuItems.count) + self.bottomMargin.constant)
        }
        set {
            super.preferredContentSize = newValue
        }
    }
    
    // MARK: - IBActions
    
    @IBAction private func closeAction(sender: UIButton) {
        self.viewModel.process(viewAction: .dismiss)
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.colors.background
        
        self.titleLabel.textColor = theme.colors.primaryContent
        self.titleLabel.font = theme.fonts.title3SB
        self.subtitleLabel.textColor = theme.colors.secondaryContent
        self.subtitleLabel.font = theme.fonts.caption1
        self.closeButton.backgroundColor = theme.roomInputTextBorder
        self.closeButton.tintColor = theme.noticeSecondaryColor
        
        if self.spaceId == SpaceListViewModel.Constants.homeSpaceId {
            let defaultAsset = ThemeService.shared().isCurrentThemeDark() ? Asset.Images.spaceHomeIconDark : Asset.Images.spaceHomeIconLight
            let avatarViewData = AvatarViewData(matrixItemId: self.spaceId, displayName: nil, avatarUrl: nil, mediaManager: session.mediaManager, fallbackImage: .image(defaultAsset.image, .center))
            self.avatarView.fill(with: avatarViewData)
        }
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        setupTableView()
        
        if self.spaceId == SpaceListViewModel.Constants.homeSpaceId {
            self.titleLabel.text = VectorL10n.titleHome
            self.subtitleLabel.text = VectorL10n.settingsTitle
            
            return
        }

        guard let space = self.session.spaceService.getSpace(withId: self.spaceId), let summary = space.summary else {
            MXLog.error("[SpaceMenuViewController] setupViews: no space found")
            return
        }
        
        let avatarViewData = AvatarViewData(matrixItemId: summary.roomId, displayName: summary.displayName, avatarUrl: summary.avatar, mediaManager: self.session.mediaManager, fallbackImage: .matrixItem(summary.roomId, summary.displayName))

        self.titleLabel.text = space.summary?.displayName
        // TODO: display members instead once done on android
//        self.subtitleLabel.text = space.membersId.count == 1 ? VectorL10n.roomTitleOneMember :
//            VectorL10n.roomTitleMembers("\(space.membersId.count)")
        self.subtitleLabel.text = summary.topic
        self.avatarView.fill(with: avatarViewData)
        
        self.closeButton.layer.masksToBounds = true
        self.closeButton.layer.cornerRadius = self.closeButton.bounds.height / 2
    }
    
    private func setupTableView() {
        self.tableView.separatorStyle = .none
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = Constants.estimatedRowHeight
        self.tableView.allowsSelection = true
        self.tableView.register(cellType: SpaceMenuListViewCell.self)
        self.tableView.register(cellType: SpaceMenuSwitchViewCell.self)
        self.tableView.tableFooterView = UIView()
    }
    
    private func render(viewState: SpaceMenuViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .loaded:
            self.renderLoaded()
        case .leaveOptions(let displayName, let isAdmin):
            self.renderLeaveOptions(displayName: displayName, isAdmin: isAdmin)
        case .error(let error):
            self.render(error: error)
        case .deselect:
            self.renderDeselect()
        }
    }
    
    private func renderLoading() {
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
    }
    
    private func renderLoaded() {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.renderDeselect()
    }
    
    private func renderLeaveOptions(displayName: String, isAdmin: Bool) {
        var message = VectorL10n.leaveSpaceMessage(displayName)

        if isAdmin {
            message += "\n\n" + VectorL10n.leaveSpaceMessageAdminWarning
        }

        let alert = UIAlertController(title: VectorL10n.leaveSpaceTitle(displayName), message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: VectorL10n.leaveSpaceOnlyAction, style: .default, handler: { [weak self] action in
            self?.viewModel.process(viewAction: .leaveSpaceAndKeepRooms)
        }))
        alert.addAction(UIAlertAction(title: VectorL10n.leaveSpaceAndAllRoomsAction, style: .destructive, handler: { [weak self] action in
            self?.viewModel.process(viewAction: .leaveSpaceAndLeaveRooms)
        }))
        alert.addAction(UIAlertAction(title: VectorL10n.cancel, style: .cancel, handler: { [weak self] action in
            self?.renderDeselect()
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func render(error: Error) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }
    
    private func renderDeselect() {
        if let selectedRow = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: selectedRow, animated: true)
        }
    }
}

// MARK: - SlidingModalPresentable

extension SpaceMenuViewController: SlidingModalPresentable {
    
    func allowsDismissOnBackgroundTap() -> Bool {
        return true
    }
    
    func layoutHeightFittingWidth(_ width: CGFloat) -> CGFloat {
        return self.preferredContentSize.height
    }
    
}

// MARK: - SpaceMenuViewModelViewDelegate

extension SpaceMenuViewController: SpaceMenuViewModelViewDelegate {
    func spaceMenuViewModel(_ viewModel: SpaceMenuViewModelType, didUpdateViewState viewSate: SpaceMenuViewState) {
        self.render(viewState: viewSate)
    }
}

// MARK: - UITableViewDataSource

extension SpaceMenuViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.menuItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewData = viewModel.menuItems[indexPath.row]
        
        let cell = viewData.style == .toggle ? tableView.dequeueReusableCell(for: indexPath, cellType: SpaceMenuSwitchViewCell.self) :
                        tableView.dequeueReusableCell(for: indexPath, cellType: SpaceMenuListViewCell.self)
        
        if let cell = cell as? SpaceMenuCell {
            cell.update(theme: self.theme)
            cell.update(with: viewData)
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension SpaceMenuViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.viewModel.process(viewAction: .selectRow(at: indexPath))
    }
}
