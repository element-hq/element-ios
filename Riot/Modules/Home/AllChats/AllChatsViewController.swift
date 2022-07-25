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
    
    // MARK: - Private
    
    private let searchController = UISearchController(searchResultsController: nil)
    private var spaceSelectorBridgePresenter: SpaceSelectorBottomSheetCoordinatorBridgePresenter?
    private var createSpaceCoordinator: SpaceCreationCoordinator?
    
    static override func instantiate() -> Self {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "AllChatsViewController") as? Self else {
            fatalError("No view controller of type \(self) in the main storyboard")
        }
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recentsTableView.tag = RecentsDataSourceMode.allChats.rawValue
        recentsTableView.clipsToBounds = false
        recentsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -70).isActive = true
        
        setNavTile()
        setLargeTitleDisplayMode(.automatic)

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
        let menu = UIMenu(children: [
            UIAction(title: VectorL10n.roomRecentsJoinRoom,
                     image: Asset.Images.homeFabJoinRoom.image,
                     discoverabilityTitle: VectorL10n.roomRecentsJoinRoom,
                     handler: { [weak self] action in
                self?.joinARoom()
            }),
            UIAction(title: VectorL10n.roomRecentsCreateEmptyRoom,
                     image: Asset.Images.homeFabCreateRoom.image,
                     discoverabilityTitle: VectorL10n.roomRecentsCreateEmptyRoom,
                     handler: { [weak self] action in
                self?.createNewRoom()
            }),
            UIAction(title: VectorL10n.roomRecentsStartChatWith,
                     image: Asset.Images.sideMenuActionIconFeedback.image,
                     discoverabilityTitle: VectorL10n.roomRecentsStartChatWith,
                     handler: { [weak self] action in
                self?.startChat()
            })
        ])
        
        let panel = AllChatsActionPanelView.loadFromNib()
        panel.editButton.showsMenuAsPrimaryAction = true
        panel.editButton.menu = menu
        
        panel.spaceButton .addTarget(self, action: #selector(showSpaceSelectorAction(sender:)), for: .touchUpInside)

        view?.addSubview(panel)
        panel.translatesAutoresizingMaskIntoConstraints = false
        panel.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        panel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        panel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        panel.heightAnchor.constraint(equalToConstant: 70).isActive = true
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

    private func setNavTile() {
        self.tabBarController?.title = self.dataSource?.currentSpace?.summary?.displayname ?? VectorL10n.allChatsTitle
    }
    
    private func showCreateSpace(parentSpaceId: String?) {
        let coordinator = SpaceCreationCoordinator(parameters: SpaceCreationCoordinatorParameters(session: self.mainSession))
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
            self.tabBarController?.title = VectorL10n.allChatsTitle

            return
        }

        guard let space = self.mainSession.spaceService.getSpace(withId: spaceId) else {
            MXLog.warning("[AllChatsViewController] switchSpace: no space found with id \(spaceId)")
            return
        }
        
        self.dataSource.currentSpace = space
        setNavTile()
        self.recentsTableView.setContentOffset(.zero, animated: true)
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
