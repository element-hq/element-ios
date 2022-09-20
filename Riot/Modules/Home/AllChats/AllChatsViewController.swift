// 
// Copyright 2022 New Vector Ltd
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

// swiftlint:disable file_length

import UIKit
import Reusable

protocol AllChatsViewControllerDelegate: AnyObject {
    func allChatsViewControllerDidCompleteAuthentication(_ allChatsViewController: AllChatsViewController)
    func allChatsViewController(_ allChatsViewController: AllChatsViewController, didSelectRoomWithParameters roomNavigationParameters: RoomNavigationParameters, completion: @escaping () -> Void)
    func allChatsViewController(_ allChatsViewController: AllChatsViewController, didSelectRoomPreviewWithParameters roomPreviewNavigationParameters: RoomPreviewNavigationParameters, completion: (() -> Void)?)
    func allChatsViewController(_ allChatsViewController: AllChatsViewController, didSelectContact contact: MXKContact, with presentationParameters: ScreenPresentationParameters)
}

class AllChatsViewController: HomeViewController {
    
    // MARK: - Class methods
    
    static override func nib() -> UINib! {
        return UINib(nibName: String(describing: self), bundle: Bundle(for: self.classForCoder()))
    }
    
    static override func instantiate() -> Self {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "AllChatsViewController") as? Self else {
            fatalError("No view controller of type \(self) in the main storyboard")
        }
        return viewController
    }
    
    // MARK: - Properties
    
    weak var allChatsDelegate: AllChatsViewControllerDelegate?
    
    // MARK: - Private
    
    private let searchController = UISearchController(searchResultsController: nil)
    
    private let spaceActionProvider = AllChatsSpaceActionProvider()
    
    private let editActionProvider = AllChatsEditActionProvider()

    private var spaceSelectorBridgePresenter: SpaceSelectorBottomSheetCoordinatorBridgePresenter?
    
    private var childCoordinators: [Coordinator] = []
    
    private let tableViewPaginationThrottler = MXThrottler(minimumDelay: 0.1)
    
    private var reviewSessionAlertHasBeenDisplayed: Bool = false
    
    private var bannerView: UIView? {
        didSet {
            bannerView?.translatesAutoresizingMaskIntoConstraints = false
            set(tableHeadeView: bannerView)
        }
    }
    
    private var isOnboardingCoordinatorPreparing: Bool = false

    private var allChatsOnboardingCoordinatorBridgePresenter: AllChatsOnboardingCoordinatorBridgePresenter?
    
    private var currentAlert: UIAlertController?
    
    // MARK: - SplitViewMasterViewControllerProtocol
    
    // References on the currently selected room
    private(set) var selectedRoomId: String?
    private(set) var selectedEventId: String?
    private(set) var selectedRoomSession: MXSession?
    private(set) var selectedRoomPreviewData: RoomPreviewData?
    
    // References on the currently selected contact
    private(set) var selectedContact: MXKContact?
    
    // Reference to the current onboarding flow. It is always nil unless the flow is being presented.
    private(set) var onboardingCoordinatorBridgePresenter: OnboardingCoordinatorBridgePresenter?
    
    // Tell whether the onboarding screen is preparing.
    private(set) var isOnboardingInProgress: Bool = false

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        editActionProvider.delegate = self
        spaceActionProvider.delegate = self
        
        recentsTableView.tag = RecentsDataSourceMode.allChats.rawValue
        recentsTableView.clipsToBounds = false
        recentsTableView.register(RecentEmptySectionTableViewCell.nib, forCellReuseIdentifier: RecentEmptySectionTableViewCell.reuseIdentifier)
        recentsTableView.register(RecentEmptySpaceSectionTableViewCell.nib, forCellReuseIdentifier: RecentEmptySpaceSectionTableViewCell.reuseIdentifier)
        recentsTableView.register(RecentsInvitesTableViewCell.nib, forCellReuseIdentifier: RecentsInvitesTableViewCell.reuseIdentifier)
        recentsTableView.contentInsetAdjustmentBehavior = .automatic
        
        updateUI()
        
        navigationItem.largeTitleDisplayMode = .automatic
        navigationController?.navigationBar.prefersLargeTitles = true

        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.delegate = self

        NotificationCenter.default.addObserver(self, selector: #selector(self.setupEditOptions), name: AllChatsLayoutSettingsManager.didUpdateSettings, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isToolbarHidden = false
        self.navigationController?.toolbar.tintColor = ThemeService.shared().theme.colors.accent
        if self.navigationItem.searchController == nil {
            self.navigationItem.searchController = searchController
        }

        NotificationCenter.default.addObserver(self, selector: #selector(self.spaceListDidChange), name: MXSpaceService.didInitialise, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.spaceListDidChange), name: MXSpaceService.didBuildSpaceGraph, object: nil)
        
        set(tableHeadeView: self.bannerView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Check whether we're not logged in
        let authIsShown: Bool
        if MXKAccountManager.shared().accounts.isEmpty {
            showOnboardingFlow()
            authIsShown = true
        } else {
            // Display a login screen if the account is soft logout
            // Note: We support only one account
            if let account = MXKAccountManager.shared().accounts.first, account.isSoftLogout {
                showSoftLogoutOnboardingFlow(with: account.mxCredentials)
                authIsShown = true
            } else {
                authIsShown = false
            }
        }
        
        guard !authIsShown else {
            return
        }

        AppDelegate.theDelegate().checkAppVersion()

        if BuildSettings.newAppLayoutEnabled && !RiotSettings.shared.allChatsOnboardingHasBeenDisplayed {
            self.showAllChatsOnboardingScreen()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.isToolbarHidden = true
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate { context in
            self.recentsTableView?.tableHeaderView?.layoutIfNeeded()
            self.recentsTableView?.tableHeaderView = self.recentsTableView?.tableHeaderView
        }
    }
    
    // MARK: - Public
    
    func switchSpace(withId spaceId: String?) {
        searchController.isActive = false

        guard let spaceId = spaceId else {
            self.dataSource?.currentSpace = nil
            updateUI()

            return
        }

        guard let space = self.mainSession.spaceService.getSpace(withId: spaceId) else {
            MXLog.warning("[AllChatsViewController] switchSpace: no space found with id \(spaceId)")
            return
        }
        
        self.dataSource.currentSpace = space
        updateUI()
        
        self.recentsTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }

    override var recentsDataSourceMode: RecentsDataSourceMode {
        .allChats
    }
    
    override func addMatrixSession(_ mxSession: MXSession!) {
        super.addMatrixSession(mxSession)
        
        if let dataSource = dataSource, !dataSource.mxSessions.contains(where: { $0 as? MXSession == mxSession }) {
            dataSource.addMatrixSession(mxSession)
            // Setting the delegate is required to send a RecentsViewControllerDataReadyNotification.
            // Without this, when clearing the cache we end up with an infinite green spinner.
            (dataSource as? RecentsDataSource)?.setDelegate(self, andRecentsDataSourceMode: recentsDataSourceMode)
        } else {
            initDataSource()
        }
    }
    
    override func removeMatrixSession(_ mxSession: MXSession!) {
        super.removeMatrixSession(mxSession)
        
        guard let dataSource = dataSource else { return }
        dataSource.removeMatrixSession(mxSession)
        
        if dataSource.mxSessions.isEmpty {
            // The user logged out -> we need to reset the data source
            displayList(nil)
        }
    }
    
    private func initDataSource() {
        guard self.dataSource == nil, let mainSession = self.mxSessions.first as? MXSession else {
            return
        }
        
        MXLog.debug("[AllChatsViewController] initDataSource")
        let recentsListService = RecentsListService(withSession: mainSession)
        let recentsDataSource = RecentsDataSource(matrixSession: mainSession, recentsListService: recentsListService)
        displayList(recentsDataSource)
        recentsDataSource?.setDelegate(self, andRecentsDataSourceMode: self.recentsDataSourceMode)
    }
    
    @objc private func spaceListDidChange() {
        guard self.editActionProvider.shouldUpdate(with: self.mainSession, parentSpace: self.dataSource?.currentSpace) else {
            return
        }
        
        updateUI()
    }

    @objc private func addFabButton() {
        // Nothing to do. We don't need FAB
    }

    @objc private func sections() -> Array<Int> {
        return [
            RecentsDataSourceSectionType.directory.rawValue,
            RecentsDataSourceSectionType.invites.rawValue,
            RecentsDataSourceSectionType.favorites.rawValue,
            RecentsDataSourceSectionType.people.rawValue,
            RecentsDataSourceSectionType.allChats.rawValue,
            RecentsDataSourceSectionType.lowPriority.rawValue,
            RecentsDataSourceSectionType.serverNotice.rawValue,
            RecentsDataSourceSectionType.suggestedRooms.rawValue,
            RecentsDataSourceSectionType.breadcrumbs.rawValue
        ]
    }
    
    override func startActivityIndicator() {
        super.startActivityIndicator()
    }
    
    // MARK: - Actions
    
    @objc private func showSpaceSelectorAction(sender: AnyObject) {
        Analytics.shared.viewRoomTrigger = .roomList
        let currentSpaceId = self.dataSource.currentSpace?.spaceId ?? SpaceSelectorConstants.homeSpaceId
        let spaceSelectorBridgePresenter = SpaceSelectorBottomSheetCoordinatorBridgePresenter(session: self.mainSession, selectedSpaceId: currentSpaceId, showHomeSpace: true)
        spaceSelectorBridgePresenter.present(from: self, animated: true)
        spaceSelectorBridgePresenter.delegate = self
        self.spaceSelectorBridgePresenter = spaceSelectorBridgePresenter
    }
    
    // MARK: - UITableViewDataSource
    
    private func sectionType(forSectionAt index: Int) -> RecentsDataSourceSectionType? {
        guard let recentsDataSource = dataSource as? RecentsDataSource else {
            return nil
        }
        
        return recentsDataSource.sections.sectionType(forSectionIndex: index)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = sectionType(forSectionAt: section), sectionType == .invites else {
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
        
        return dataSource.tableView(tableView, numberOfRowsInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sectionType = sectionType(forSectionAt: indexPath.section), sectionType == .invites else {
            return super.tableView(tableView, cellForRowAt: indexPath)
        }
        
        return dataSource.tableView(tableView, cellForRowAt: indexPath)
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let sectionType = sectionType(forSectionAt: indexPath.section), sectionType == .invites else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
        
        return dataSource.cellHeight(at: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let sectionType = sectionType(forSectionAt: indexPath.section), sectionType == .invites else {
            super.tableView(tableView, didSelectRowAt: indexPath)
            return
        }

        showRoomInviteList()
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        super.tableView(tableView, willDisplay: cell, forRowAt: indexPath)

        guard let recentsDataSource = dataSource as? RecentsDataSource else {
            return
        }
        
        let sectionType = recentsDataSource.sections.sectionType(forSectionIndex: indexPath.section)
        // We need to trottle a bit earlier so the next section is not visible even if the tableview scrolls faster
        guard sectionType == .allChats, let numberOfRowsInSection = recentsDataSource.recentsListService.allChatsRoomListData?.counts.numberOfRooms, indexPath.row == numberOfRowsInSection - 4 else {
            return
        }
        
        tableViewPaginationThrottler.throttle {
            recentsDataSource.paginate(inSection: indexPath.section)
        }
    }

    // MARK: - Toolbar animation
    
    private var initialScrollPosition: Double = 0
    
    private func scrollPosition(of scrollView: UIScrollView) -> Double {
        return scrollView.contentOffset.y + scrollView.adjustedContentInset.top
    }

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard scrollView == recentsTableView else {
            return
        }
        
        initialScrollPosition = scrollPosition(of: scrollView)
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)

        guard scrollView == recentsTableView else {
            return
        }
        
        let scrollPosition = scrollPosition(of: scrollView)
        
        if !self.recentsTableView.isDragging && scrollPosition == 0 && self.navigationController?.isToolbarHidden == true {
            self.navigationController?.setToolbarHidden(false, animated: true)
        }

        guard self.recentsTableView.isDragging else {
            return
        }

        guard scrollPosition > 0 && scrollPosition < self.recentsTableView.contentSize.height - self.recentsTableView.bounds.height else {
            return
        }

        let isToolBarHidden: Bool = scrollPosition - initialScrollPosition > 0
        if isToolBarHidden != self.navigationController?.isToolbarHidden {
            self.navigationController?.setToolbarHidden(isToolBarHidden, animated: true)
        }
    }
    
    // MARK: - Empty view management
    
    override func updateEmptyView() {
        guard let mainSession = self.mainSession else {
            return
        }
        
        let title: String
        let informationText: String
        if let currentSpace = self.dataSource?.currentSpace {
            title = VectorL10n.allChatsEmptyViewTitle(currentSpace.summary?.displayname ?? VectorL10n.spaceTag)
            informationText = VectorL10n.allChatsEmptySpaceInformation
        } else {
            let myUser = mainSession.myUser
            let displayName = (myUser?.displayName ?? myUser?.userId) ?? ""
            let appName = AppInfo.current.displayName
            title = VectorL10n.homeEmptyViewTitle(appName, displayName)
            informationText = VectorL10n.allChatsEmptyViewInformation
        }
        
        self.emptyView?.fill(with: emptyViewArtwork,
                             title: title,
                             informationText: informationText)
    }
    
    private var emptyViewArtwork: UIImage {
        if self.dataSource?.currentSpace == nil {
            return ThemeService.shared().isCurrentThemeDark() ? Asset.Images.allChatsEmptyScreenArtworkDark.image : Asset.Images.allChatsEmptyScreenArtwork.image
        } else {
            return ThemeService.shared().isCurrentThemeDark() ? Asset.Images.allChatsEmptySpaceArtworkDark.image : Asset.Images.allChatsEmptySpaceArtwork.image
        }
    }
    
    override func shouldShowEmptyView() -> Bool {
        let shouldShowEmptyView = super.shouldShowEmptyView()
        
        if shouldShowEmptyView {
            self.navigationItem.searchController = nil
            navigationItem.largeTitleDisplayMode = .never
        } else {
            self.navigationItem.searchController = searchController
            navigationItem.largeTitleDisplayMode = .automatic
        }

        return shouldShowEmptyView
    }
    

    // MARK: - Theme management
    
    override func userInterfaceThemeDidChange() {
        super.userInterfaceThemeDidChange()
        
        guard self.toolbarItems != nil else {
            return
        }
        
        self.update(with: ThemeService.shared().theme)
    }
    
    private func update(with theme: Theme) {
        self.navigationController?.toolbar?.tintColor = theme.colors.accent
    }
    
    // MARK: - Private
    
    private func set(tableHeadeView: UIView?) {
        guard let tableView = recentsTableView else {
            return
        }
        
        tableView.tableHeaderView = tableHeadeView
        tableView.tableHeaderView?.widthAnchor.constraint(equalTo: tableView.widthAnchor).isActive = true
        tableView.tableHeaderView?.layoutIfNeeded()
        tableView.tableHeaderView = self.recentsTableView?.tableHeaderView
    }

    @objc private func setupEditOptions() {
        guard let currentSpace = self.dataSource?.currentSpace else {
            updateRightNavigationItem(with: AllChatsActionProvider().menu)
            return
        }
        
        updateRightNavigationItem(with: spaceActionProvider.updateMenu(with: mainSession, space: currentSpace) { [weak self] menu in
            self?.updateRightNavigationItem(with: menu)
        })
    }

    private func updateUI() {
        let currentSpace = self.dataSource?.currentSpace
        self.title = currentSpace?.summary?.displayname ?? VectorL10n.allChatsTitle
        
        setupEditOptions()
        updateToolbar(with: editActionProvider.updateMenu(with: mainSession, parentSpace: currentSpace, completion: { [weak self] menu in
            self?.updateToolbar(with: menu)
        }))
        updateEmptyView()
    }
    
    private func updateRightNavigationItem(with menu: UIMenu) {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), menu: menu)
    }
    
    private func updateToolbar(with menu: UIMenu) {
        self.navigationController?.isToolbarHidden = false
        self.update(with: ThemeService.shared().theme)
        self.setToolbarItems([
            UIBarButtonItem(image: Asset.Images.allChatsSpacesIcon.image, style: .done, target: self, action: #selector(self.showSpaceSelectorAction(sender: ))),
            UIBarButtonItem.flexibleSpace(),
            UIBarButtonItem(image: Asset.Images.allChatsEditIcon.image, menu: menu)
        ], animated: true)
    }
    
    private func showCreateSpace(parentSpaceId: String?) {
        let coordinator = SpaceCreationCoordinator(parameters: SpaceCreationCoordinatorParameters(session: self.mainSession, parentSpaceId: parentSpaceId))
        let presentable = coordinator.toPresentable()
        self.present(presentable, animated: true, completion: nil)
        coordinator.callback = { [weak self] result in
            guard let self = self else {
                return
            }
            
            coordinator.toPresentable().dismiss(animated: true) {
                self.remove(childCoordinator: coordinator)
                switch result {
                case .cancel:
                    break
                case .done(let spaceId):
                    self.switchSpace(withId: spaceId)
                }
            }
        }
        add(childCoordinator: coordinator)
        coordinator.start()
    }
    
    private func add(childCoordinator: Coordinator) {
        self.childCoordinators.append(childCoordinator)
    }
    
    private func remove(childCoordinator: Coordinator) {
        self.childCoordinators.append(childCoordinator)
    }
    
    private func showSpaceInvite() {
        guard let session = mainSession, let spaceRoom = dataSource.currentSpace?.room else {
            return
        }
        
        let coordinator = ContactsPickerCoordinator(session: session, room: spaceRoom, initialSearchText: nil, actualParticipants: nil, invitedParticipants: nil, userParticipant: nil)
        coordinator.delegate = self
        coordinator.start()
        add(childCoordinator: coordinator)
        present(coordinator.toPresentable(), animated: true)
    }
    
    private func showSpaceMembers() {
        guard let session = mainSession, let spaceId = dataSource.currentSpace?.spaceId else {
            return
        }
        
        let coordinator = SpaceMembersCoordinator(parameters: SpaceMembersCoordinatorParameters(userSessionsService: UserSessionsService.shared, session: session, spaceId: spaceId))
        coordinator.delegate = self
        let presentable = coordinator.toPresentable()
        presentable.presentationController?.delegate = self
        coordinator.start()
        add(childCoordinator: coordinator)
        present(presentable, animated: true, completion: nil)
    }

    private func showSpaceSettings() {
        guard let session = mainSession, let spaceId = dataSource.currentSpace?.spaceId else {
            return
        }
        
        let coordinator = SpaceSettingsModalCoordinator(parameters: SpaceSettingsModalCoordinatorParameters(session: session, spaceId: spaceId, parentSpaceId: nil))
        coordinator.callback = { [weak self] result in
            guard let self = self else { return }
            
            coordinator.toPresentable().dismiss(animated: true) {
                self.remove(childCoordinator: coordinator)
            }
        }
        
        let presentable = coordinator.toPresentable()
        presentable.presentationController?.delegate = self
        present(presentable, animated: true, completion: nil)
        coordinator.start()
        add(childCoordinator: coordinator)
    }
    
    private func showLeaveSpace() {
        guard let session = mainSession, let spaceSummary = dataSource.currentSpace?.summary else {
            return
        }
        
        let name = spaceSummary.displayname ?? VectorL10n.spaceTag
        
        let selectionHeader = MatrixItemChooserSelectionHeader(title: VectorL10n.leaveSpaceSelectionTitle,
                                                               selectAllTitle: VectorL10n.leaveSpaceSelectionAllRooms,
                                                               selectNoneTitle: VectorL10n.leaveSpaceSelectionNoRooms)
        let paramaters = MatrixItemChooserCoordinatorParameters(session: session,
                                                                title: VectorL10n.leaveSpaceTitle(name),
                                                                detail: VectorL10n.leaveSpaceMessage(name),
                                                                selectionHeader: selectionHeader,
                                                                viewProvider: LeaveSpaceViewProvider(navTitle: nil),
                                                                itemsProcessor: LeaveSpaceItemsProcessor(spaceId: spaceSummary.roomId, session: session))
        let coordinator = MatrixItemChooserCoordinator(parameters: paramaters)
        coordinator.toPresentable().presentationController?.delegate = self
        coordinator.start()
        add(childCoordinator: coordinator)
        coordinator.completion = { [weak self] result in
            // switching to home space
            self?.switchSpace(withId: nil)
            coordinator.toPresentable().dismiss(animated: true) {
                self?.remove(childCoordinator: coordinator)
            }
        }
        present(coordinator.toPresentable(), animated: true)
    }
    
    private func showRoomInviteList() {
        let invitesViewController = RoomInvitesViewController.instantiate()
        invitesViewController.userIndicatorStore = self.userIndicatorStore
        let recentsListService = RecentsListService(withSession: mainSession)
        let recentsDataSource = RecentsDataSource(matrixSession: mainSession, recentsListService: recentsListService)
        invitesViewController.displayList(recentsDataSource)
        self.navigationController?.pushViewController(invitesViewController, animated: true)
    }
    
    private func showAllChatsOnboardingScreen() {
        let allChatsOnboardingCoordinatorBridgePresenter = AllChatsOnboardingCoordinatorBridgePresenter()
        allChatsOnboardingCoordinatorBridgePresenter.completion = { [weak self] in
            RiotSettings.shared.allChatsOnboardingHasBeenDisplayed = true
            
            guard let self = self else { return }
            self.allChatsOnboardingCoordinatorBridgePresenter?.dismiss(animated: true, completion: {
                self.allChatsOnboardingCoordinatorBridgePresenter = nil
            })
        }
        
        allChatsOnboardingCoordinatorBridgePresenter.present(from: self, animated: true)
        self.allChatsOnboardingCoordinatorBridgePresenter = allChatsOnboardingCoordinatorBridgePresenter
    }
}

// MARK: - SpaceSelectorBottomSheetCoordinatorBridgePresenterDelegate
extension AllChatsViewController: SpaceSelectorBottomSheetCoordinatorBridgePresenterDelegate {
    
    func spaceSelectorBottomSheetCoordinatorBridgePresenterDidCancel(_ coordinatorBridgePresenter: SpaceSelectorBottomSheetCoordinatorBridgePresenter) {
        coordinatorBridgePresenter.dismiss(animated: true) {
            self.spaceSelectorBridgePresenter = nil
        }
    }
    
    func spaceSelectorBottomSheetCoordinatorBridgePresenterDidSelectHome(_ coordinatorBridgePresenter: SpaceSelectorBottomSheetCoordinatorBridgePresenter) {
        coordinatorBridgePresenter.dismiss(animated: true) {
            self.spaceSelectorBridgePresenter = nil
        }
        
        switchSpace(withId: nil)
    }
    
    func spaceSelectorBottomSheetCoordinatorBridgePresenter(_ coordinatorBridgePresenter: SpaceSelectorBottomSheetCoordinatorBridgePresenter, didSelectSpaceWithId spaceId: String) {
        coordinatorBridgePresenter.dismiss(animated: true) {
            self.spaceSelectorBridgePresenter = nil
        }
        
        switchSpace(withId: spaceId)
    }

    func spaceSelectorBottomSheetCoordinatorBridgePresenter(_ coordinatorBridgePresenter: SpaceSelectorBottomSheetCoordinatorBridgePresenter, didCreateSpaceWithinSpaceWithId parentSpaceId: String?) {
        coordinatorBridgePresenter.dismiss(animated: true) {
            self.spaceSelectorBridgePresenter = nil
        }
        self.showCreateSpace(parentSpaceId: parentSpaceId)
    }

}

// MARK: - UISearchResultsUpdating
extension AllChatsViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text, !searchText.isEmpty else {
            self.dataSource.search(withPatterns: nil)
            return
        }
        
        self.dataSource.search(withPatterns: [searchText])
    }

}

// MARK: - UISearchControllerDelegate
extension AllChatsViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        // Fix for https://github.com/vector-im/element-ios/issues/6680
        self.recentsTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension AllChatsViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        guard let coordinator = childCoordinators.last else {
            return
        }
        
        remove(childCoordinator: coordinator)
    }
}

// MARK: - AllChatsEditActionProviderDelegate
extension AllChatsViewController: AllChatsEditActionProviderDelegate {
    
    func allChatsEditActionProvider(_ actionProvider: AllChatsEditActionProvider, didSelect option: AllChatsEditActionProviderOption) {
        switch option {
        case .exploreRooms:
            joinARoom()
        case .createRoom:
            createNewRoom()
        case .startChat:
            startChat()
        case .createSpace:
            showCreateSpace(parentSpaceId: dataSource.currentSpace?.spaceId)
        }
    }
    
}

// MARK: - AllChatsSpaceActionProviderDelegate
extension AllChatsViewController: AllChatsSpaceActionProviderDelegate {
    func allChatsSpaceActionProvider(_ actionProvider: AllChatsSpaceActionProvider, didSelect option: AllChatsSpaceActionProviderOption) {
        switch option {
        case .invitePeople:
            showSpaceInvite()
        case .spaceMembers:
            showSpaceMembers()
        case .spaceSettings:
            showSpaceSettings()
        case .leaveSpace:
            showLeaveSpace()
        }
    }
}

// MARK: - ContactsPickerCoordinatorDelegate
extension AllChatsViewController: ContactsPickerCoordinatorDelegate {
    
    func contactsPickerCoordinatorDidStartLoading(_ coordinator: ContactsPickerCoordinatorProtocol) {
    }
    
    func contactsPickerCoordinatorDidEndLoading(_ coordinator: ContactsPickerCoordinatorProtocol) {
    }
    
    func contactsPickerCoordinatorDidClose(_ coordinator: ContactsPickerCoordinatorProtocol) {
        remove(childCoordinator: coordinator)
    }
    
}

// MARK: - SpaceMembersCoordinatorDelegate
extension AllChatsViewController: SpaceMembersCoordinatorDelegate {
    
    func spaceMembersCoordinatorDidCancel(_ coordinator: SpaceMembersCoordinatorType) {
        coordinator.toPresentable().dismiss(animated: true) {
            self.remove(childCoordinator: coordinator)
        }
    }
    
}

// MARK: - BannerPresentationProtocol
extension AllChatsViewController: BannerPresentationProtocol {
    func presentBannerView(_ bannerView: UIView, animated: Bool) {
        self.bannerView = bannerView
    }
    
    func dismissBannerView(animated: Bool) {
        self.bannerView = nil
    }
}

// TODO: The `MasterTabBarViewController` is called from the entire app through the `LegacyAppDelegate`. this part of the code should be moved into `AppCoordinator`
// MARK: - SplitViewMasterViewControllerProtocol
extension AllChatsViewController: SplitViewMasterViewControllerProtocol {

    /// Release the current selected item (if any).
    func releaseSelectedItem() {
        selectedRoomId = nil
        selectedEventId = nil
        selectedRoomSession = nil
        selectedRoomPreviewData = nil
        selectedContact = nil
    }
    
    /// Refresh the missed conversations badges on tab bar icon
    func refreshTabBarBadges() {
        // Nothing to do here as we don't have tab bar
    }
    
    /// Verify the current device if needed.
    ///
    /// - Parameters:
    ///   - session: the matrix session.
    func presentVerifyCurrentSessionAlertIfNeeded(with session: MXSession) {
        guard !RiotSettings.shared.hideVerifyThisSessionAlert, !reviewSessionAlertHasBeenDisplayed, !isOnboardingInProgress else {
            return
        }
        
        reviewSessionAlertHasBeenDisplayed = true

        // Force verification if required by the HS configuration
        guard !session.vc_homeserverConfiguration().encryption.isSecureBackupRequired else {
            MXLog.debug("[AllChatsViewController] presentVerifyCurrentSessionAlertIfNeededWithSession: Force verification of the device")
            AppDelegate.theDelegate().presentCompleteSecurity(for: session)
            return
        }

        presentVerifyCurrentSessionAlert(with: session)
    }

    /// Verify others device if needed.
    ///
    /// - Parameters:
    ///   - session: the matrix session.
    func presentReviewUnverifiedSessionsAlertIfNeeded(with session: MXSession) {
        guard !RiotSettings.shared.hideReviewSessionsAlert, !reviewSessionAlertHasBeenDisplayed else {
            return
        }
        
        let devices = mainSession.crypto.devices(forUser: mainSession.myUserId).values
        var userHasOneUnverifiedDevice = false
        for device in devices {
            if !device.trustLevel.isCrossSigningVerified {
                userHasOneUnverifiedDevice = true
                break
            }
        }
        
        if userHasOneUnverifiedDevice {
            reviewSessionAlertHasBeenDisplayed = true
            presentReviewUnverifiedSessionsAlert(with: session)
        }
    }
    
    func showOnboardingFlow() {
        MXLog.debug("[AllChatsViewController] showOnboardingFlow")
        self.showOnboardingFlowAndResetSessionFlags(true)
    }

    /// Display the onboarding flow configured to log back into a soft logout session.
    ///
    /// - Parameters:
    ///   - credentials: the credentials of the soft logout session.
    func showSoftLogoutOnboardingFlow(with credentials: MXCredentials?) {
        // This method can be called after the user chooses to clear their data as the MXSession
        // is opened to call logout from. So we only set the credentials when authentication isn't
        // in progress to prevent a second soft logout screen being shown.
        guard self.onboardingCoordinatorBridgePresenter == nil && !self.isOnboardingCoordinatorPreparing else {
            return
        }

        MXLog.debug("[AllChatsViewController] showAuthenticationScreenAfterSoftLogout")
        AuthenticationService.shared.softLogoutCredentials = credentials
        self.showOnboardingFlowAndResetSessionFlags(false)
    }

    /// Open the room with the provided identifier in a specific matrix session.
    ///
    /// - Parameters:
    ///   - parameters: the presentation parameters that contains room information plus display information.
    ///   - completion: the block to execute at the end of the operation.
    func selectRoom(with parameters: RoomNavigationParameters, completion: @escaping () -> Void) {
        releaseSelectedItem()
        
        selectedRoomId = parameters.roomId
        selectedEventId = parameters.eventId
        selectedRoomSession = parameters.mxSession

        allChatsDelegate?.allChatsViewController(self, didSelectRoomWithParameters: parameters, completion: completion)

        refreshSelectedControllerSelectedCellIfNeeded()
    }
    
    /// Open the RoomViewController to display the preview of a room that is unknown for the user.
    /// This room can come from an email invitation link or a simple link to a room.
    /// - Parameters:
    ///   - parameters: the presentation parameters that contains room preview information plus display information.
    ///   - completion: the block to execute at the end of the operation.
    func selectRoomPreview(with parameters: RoomPreviewNavigationParameters, completion: (() -> Void)?) {
        releaseSelectedItem()
        
        let roomPreviewData = parameters.previewData
        
        selectedRoomPreviewData = roomPreviewData
        selectedRoomId = roomPreviewData.roomId
        selectedRoomSession = roomPreviewData.mxSession

        allChatsDelegate?.allChatsViewController(self, didSelectRoomPreviewWithParameters: parameters, completion: completion)

        refreshSelectedControllerSelectedCellIfNeeded()
    }

    /// Open a ContactDetailsViewController to display the information of the provided contact.
    func select(_ contact: MXKContact) {
        let presentationParameters = ScreenPresentationParameters(restoreInitialDisplay: true, stackAboveVisibleViews: false)
        select(contact, with: presentationParameters)
    }
    
    /// Open a ContactDetailsViewController to display the information of the provided contact.
    func select(_ contact: MXKContact, with presentationParameters: ScreenPresentationParameters) {
        releaseSelectedItem()
        
        selectedContact = contact
        
        allChatsDelegate?.allChatsViewController(self, didSelectContact: contact, with: presentationParameters)

        refreshSelectedControllerSelectedCellIfNeeded()
    }

    /// The current number of rooms with missed notifications, including the invites.
    func missedDiscussionsCount() -> UInt {
        guard let session = mxSessions as? [MXSession] else {
            return 0
        }
        
        return session.reduce(0) { $0 + $1.vc_missedDiscussionsCount() }
    }

    /// The current number of rooms with unread highlighted messages.
    func missedHighlightDiscussionsCount() -> UInt {
        guard let session = mxSessions as? [MXSession] else {
            return 0
        }
        
        return session.reduce(0) { $0 + $1.missedHighlightDiscussionsCount() }
    }
    
    /// Emulated `UItabBarViewController.selectedViewController` member
    var selectedViewController: UIViewController? {
        return self
    }
    
    var tabBar: UITabBar? {
        return nil
    }
    
    // MARK: - Private
    
    private func presentVerifyCurrentSessionAlert(with session: MXSession) {
        MXLog.debug("[AllChatsViewController] presentVerifyCurrentSessionAlertWithSession")
        
        currentAlert?.dismiss(animated: true, completion: nil)
        
        let alert = UIAlertController(title: VectorL10n.keyVerificationSelfVerifyCurrentSessionAlertTitle,
                                      message: VectorL10n.keyVerificationSelfVerifyCurrentSessionAlertMessage,
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: VectorL10n.keyVerificationSelfVerifyCurrentSessionAlertValidateAction,
                                      style: .default,
                                      handler: { action in
            AppDelegate.theDelegate().presentCompleteSecurity(for: session)
        }))
        
        alert.addAction(UIAlertAction(title: VectorL10n.later, style: .cancel))
        
        alert.addAction(UIAlertAction(title: VectorL10n.doNotAskAgain,
                                      style: .destructive,
                                      handler: { action in
            RiotSettings.shared.hideVerifyThisSessionAlert = true
        }))
        
        self.present(alert, animated: true)
        currentAlert = alert
    }

    private func presentReviewUnverifiedSessionsAlert(with session: MXSession) {
        MXLog.debug("[AllChatsViewController] presentReviewUnverifiedSessionsAlert")
        
        currentAlert?.dismiss(animated: true, completion: nil)
        
        let alert = UIAlertController(title: VectorL10n.keyVerificationSelfVerifyUnverifiedSessionsAlertTitle,
                                      message: VectorL10n.keyVerificationSelfVerifyUnverifiedSessionsAlertMessage,
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: VectorL10n.keyVerificationSelfVerifyUnverifiedSessionsAlertValidateAction,
                                      style: .default,
                                      handler: { action in
            self.showSettingsSecurityScreen(with: session)
        }))
        
        alert.addAction(UIAlertAction(title: VectorL10n.later, style: .cancel))
        
        alert.addAction(UIAlertAction(title: VectorL10n.doNotAskAgain, style: .destructive, handler: { action in
            RiotSettings.shared.hideReviewSessionsAlert = true
        }))
        
        present(alert, animated: true)
        currentAlert = alert
    }

    private func showSettingsSecurityScreen(with session: MXSession) {
        guard let settingsViewController = SettingsViewController.instantiate() else {
            MXLog.warning("[AllChatsViewController] showSettingsSecurityScreen: cannot instantiate SettingsViewController")
            return
        }
        
        guard let securityViewController = SecurityViewController.instantiate(withMatrixSession: session) else {
            MXLog.warning("[AllChatsViewController] showSettingsSecurityScreen: cannot instantiate SecurityViewController")
            return
        }
        
        settingsViewController.loadViewIfNeeded()
        AppDelegate.theDelegate().restoreInitialDisplay {
            self.navigationController?.viewControllers = [self, settingsViewController, securityViewController]
        }
    }
    
    private func showOnboardingFlowAndResetSessionFlags(_ resetSessionFlags: Bool) {
        // Check whether an authentication screen is not already shown or preparing
        guard self.onboardingCoordinatorBridgePresenter == nil && !self.isOnboardingCoordinatorPreparing else {
            return
        }
        
        self.isOnboardingCoordinatorPreparing = true
        self.isOnboardingInProgress = true
        
        if resetSessionFlags {
            resetReviewSessionsFlags()
        }
        
        AppDelegate.theDelegate().restoreInitialDisplay {
            self.presentOnboardingFlow()
        }
    }

    private func resetReviewSessionsFlags() {
        reviewSessionAlertHasBeenDisplayed = false
        RiotSettings.shared.hideVerifyThisSessionAlert = false
        RiotSettings.shared.hideReviewSessionsAlert = false
    }
    
    private func presentOnboardingFlow() {
        MXLog.debug("[AllChatsViewController] presentOnboardingFlow")
        
        let onboardingCoordinatorBridgePresenter = OnboardingCoordinatorBridgePresenter()
        onboardingCoordinatorBridgePresenter.completion = { [weak self] in
            guard let self = self else { return }
            
            self.onboardingCoordinatorBridgePresenter?.dismiss(animated: true, completion: {
                self.onboardingCoordinatorBridgePresenter = nil
            })
            
            self.isOnboardingInProgress = false   // Must be set before calling didCompleteAuthentication
            self.allChatsDelegate?.allChatsViewControllerDidCompleteAuthentication(self)
        }
        
        onboardingCoordinatorBridgePresenter.present(from: self, animated: true)
        self.onboardingCoordinatorBridgePresenter = onboardingCoordinatorBridgePresenter
        self.isOnboardingCoordinatorPreparing = false
    }
    
    private func refreshSelectedControllerSelectedCellIfNeeded() {
        guard splitViewController != nil else {
            return
        }
        
        // Refresh selected cell without scrolling the selected cell (We suppose it's visible here)
        self.refreshCurrentSelectedCell(false)
    }
}
