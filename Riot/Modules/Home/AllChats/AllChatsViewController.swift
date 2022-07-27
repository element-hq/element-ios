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
    
    // MARK: - Constants
    
    private enum Constants {
        static let actionPanelHeight: Double = 64
    }
    
    // MARK: - Class methods
    
    static override func nib() -> UINib! {
        return UINib(nibName: String(describing: self), bundle: Bundle(for: self.classForCoder()))
    }
    
    // MARK: - Private
    
    private let searchController = UISearchController(searchResultsController: nil)
    private let actionPanelView = AllChatsActionPanelView.loadFromNib()
    
    private let editActionProvider = AllChatsEditActionProvider()

    private var spaceSelectorBridgePresenter: SpaceSelectorBottomSheetCoordinatorBridgePresenter?
    private var createSpaceCoordinator: SpaceCreationCoordinator?
    
    private var childCoordinators: [Coordinator] = []
    
    static override func instantiate() -> Self {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "AllChatsViewController") as? Self else {
            fatalError("No view controller of type \(self) in the main storyboard")
        }
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        editActionProvider.delegate = self
        
        recentsTableView.tag = RecentsDataSourceMode.allChats.rawValue
        recentsTableView.clipsToBounds = false
        recentsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Constants.actionPanelHeight).isActive = true
        
        updateUI()
        vc_setLargeTitleDisplayMode(.automatic)

        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self

        self.setupEditOptions()
        NotificationCenter.default.addObserver(self, selector: #selector(self.setupEditOptions), name: AllChatsLayoutSettingsManager.didUpdateSettings, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.tabBarController?.navigationItem.searchController == nil {
            self.tabBarController?.navigationItem.searchController = searchController
        }
    }
    
    // MARK: - HomeViewController
    
    override var recentsDataSourceMode: RecentsDataSourceMode {
        .allChats
    }
    
    @objc private func addFabButton() {
        actionPanelView.editButton.showsMenuAsPrimaryAction = true
        actionPanelView.spaceButton .addTarget(self, action: #selector(showSpaceSelectorAction(sender:)), for: .touchUpInside)

        view?.addSubview(actionPanelView)
        actionPanelView.translatesAutoresizingMaskIntoConstraints = false
        actionPanelView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        actionPanelView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        actionPanelView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        actionPanelView.heightAnchor.constraint(equalToConstant: Constants.actionPanelHeight).isActive = true
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
            RecentsDataSourceSectionType.recentRooms.rawValue
        ]
    }
    
    // MARK: - Actions
    
    @objc private func showSpaceSelectorAction(sender: UIButton) {
        let currentSpaceId = self.dataSource.currentSpace?.spaceId ?? SpaceSelectorListItemDataHomeSpaceId
        let spaceSelectorBridgePresenter = SpaceSelectorBottomSheetCoordinatorBridgePresenter(session: self.mainSession, selectedSpaceId: currentSpaceId, showHomeSpace: true)
        spaceSelectorBridgePresenter.present(from: self, animated: true)
        spaceSelectorBridgePresenter.delegate = self
        self.spaceSelectorBridgePresenter = spaceSelectorBridgePresenter
    }
    
    // MARK: - Private
    
    @objc private func setupEditOptions() {
        self.tabBarController?.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), menu: AllChatsActionProvider().menu)
    }

    private func updateUI() {
        self.tabBarController?.title = self.dataSource?.currentSpace?.summary?.displayname ?? VectorL10n.allChatsTitle
        
        actionPanelView.editButton.menu = editActionProvider.updateMenu(with: mainSession, parentSpace: dataSource?.currentSpace, completion: { [weak self] menu in
            self?.actionPanelView.editButton.menu = menu
        })
    }
    
    private func showCreateSpace(parentSpaceId: String?) {
        let coordinator = SpaceCreationCoordinator(parameters: SpaceCreationCoordinatorParameters(session: self.mainSession, parentSpaceId: parentSpaceId))
        let presentable = coordinator.toPresentable()
        self.present(presentable, animated: true, completion: nil)
        coordinator.callback = { [weak self] result in
            guard let self = self else {
                return
            }
            
            self.createSpaceCoordinator?.toPresentable().dismiss(animated: true) {
                self.createSpaceCoordinator = nil
                switch result {
                case .cancel:
                    break
                case .done(let spaceId):
                    self.switchSpace(withId: spaceId)
                }
            }
        }
        coordinator.start()
        
        self.createSpaceCoordinator = coordinator
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
        self.spaceSelectorBridgePresenter = nil
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
    
    func allChatsEditActionProvider(_ ationProvider: AllChatsEditActionProvider, didSelect option: AllChatsEditActionProviderOption) {
        switch option {
        case .exploreRooms:
            joinARoom()
        case .createRoom:
            createNewRoom()
        case .startChat:
            startChat()
        case .invitePeople:
            showSpaceInvite()
        case .spaceMembers:
            showSpaceMembers()
        case .spaceSettings:
            showSpaceSettings()
        case .leaveSpace:
            showLeaveSpace()
        case .createSpace:
            showCreateSpace(parentSpaceId: dataSource.currentSpace?.spaceId)
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
