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

import UIKit
import Reusable

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
    
    // MARK: - Private
    
    private let searchController = UISearchController(searchResultsController: nil)
    
    private let spaceActionProvider = AllChatsSpaceActionProvider()
    
    private let editActionProvider = AllChatsEditActionProvider()

    private var spaceSelectorBridgePresenter: SpaceSelectorBottomSheetCoordinatorBridgePresenter?
    
    private var childCoordinators: [Coordinator] = []
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        editActionProvider.delegate = self
        spaceActionProvider.delegate = self
        
        recentsTableView.tag = RecentsDataSourceMode.allChats.rawValue
        recentsTableView.clipsToBounds = false
        
        updateUI()
        vc_setLargeTitleDisplayMode(.automatic)

        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self

        NotificationCenter.default.addObserver(self, selector: #selector(self.setupEditOptions), name: AllChatsLayoutSettingsManager.didUpdateSettings, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isToolbarHidden = false
        self.navigationController?.toolbar.tintColor = ThemeService.shared().theme.colors.accent
        if self.tabBarController?.navigationItem.searchController == nil {
            self.tabBarController?.navigationItem.searchController = searchController
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.spaceListDidChange), name: MXSpaceService.didInitialise, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.spaceListDidChange), name: MXSpaceService.didBuildSpaceGraph, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.isToolbarHidden = true
    }
    
    // MARK: - HomeViewController
    
    override var recentsDataSourceMode: RecentsDataSourceMode {
        .allChats
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
    
    // MARK: - Actions
    
    @objc private func showSpaceSelectorAction(sender: AnyObject) {
        let currentSpaceId = self.dataSource.currentSpace?.spaceId ?? SpaceSelectorConstants.homeSpaceId
        let spaceSelectorBridgePresenter = SpaceSelectorBottomSheetCoordinatorBridgePresenter(session: self.mainSession, selectedSpaceId: currentSpaceId, showHomeSpace: true)
        spaceSelectorBridgePresenter.present(from: self, animated: true)
        spaceSelectorBridgePresenter.delegate = self
        self.spaceSelectorBridgePresenter = spaceSelectorBridgePresenter
    }
    
    // MARK: - Toolbar animation
    
    private var lastScrollPosition: Double = 0

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        lastScrollPosition = self.recentsTableView.contentOffset.y
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        
        if self.recentsTableView.contentOffset.y == 0 {
            self.navigationController?.setToolbarHidden(false, animated: true)
        }

        guard self.recentsTableView.isDragging else {
            return
        }

        let scrollPosition = max(self.recentsTableView.contentOffset.y, 0)
        guard scrollPosition < self.recentsTableView.contentSize.height - self.recentsTableView.bounds.height else {
            return
        }

        self.navigationController?.setToolbarHidden(scrollPosition - lastScrollPosition > 0, animated: true)
        lastScrollPosition = scrollPosition
    }
    
    // MARK: - Theme management
    
    override func userInterfaceThemeDidChange() {
        super.userInterfaceThemeDidChange()
        
        guard self.tabBarController?.toolbarItems != nil else {
            return
        }
        
        self.update(with: ThemeService.shared().theme)
    }
    
    private func update(with theme: Theme) {
        self.navigationController?.toolbar?.tintColor = theme.colors.accent
    }
    
    // MARK: - Private
    
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
        self.tabBarController?.title = currentSpace?.summary?.displayname ?? VectorL10n.allChatsTitle
        
        setupEditOptions()
        updateToolbar(with: editActionProvider.updateMenu(with: mainSession, parentSpace: currentSpace, completion: { [weak self] menu in
            self?.updateToolbar(with: menu)
        }))
    }
    
    private func updateRightNavigationItem(with menu: UIMenu) {
        self.tabBarController?.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), menu: menu)
    }
    
    private func updateToolbar(with menu: UIMenu) {
        self.navigationController?.isToolbarHidden = false
        self.update(with: ThemeService.shared().theme)
        self.tabBarController?.setToolbarItems([
            UIBarButtonItem(image: UIImage(systemName: "square.grid.2x2"), style: .done, target: self, action: #selector(self.showSpaceSelectorAction(sender: ))),
            UIBarButtonItem.flexibleSpace(),
            UIBarButtonItem(image: UIImage(systemName: "square.and.pencil"), menu: menu)
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
    
    private func switchSpace(withId spaceId: String?) {
        searchController.isActive = false

        guard let spaceId = spaceId else {
            self.dataSource.currentSpace = nil
            updateUI()

            return
        }

        guard let space = self.mainSession.spaceService.getSpace(withId: spaceId) else {
            MXLog.warning("[AllChatsViewController] switchSpace: no space found with id \(spaceId)")
            return
        }
        
        self.dataSource.currentSpace = space
        updateUI()
        
        self.recentsTableView.setContentOffset(.zero, animated: true)
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
