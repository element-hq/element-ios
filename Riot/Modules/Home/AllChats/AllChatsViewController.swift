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
        recentsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Constants.actionPanelHeight).isActive = true
        
        self.tabBarController?.title = VectorL10n.allChatsTitle
        vc_setLargeTitleDisplayMode(.automatic)

        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self

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
        let editMenu = UIMenu(children: [
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
        
        actionPanelView.editButton.showsMenuAsPrimaryAction = true
        actionPanelView.editButton.menu = editMenu
        self.setupEditOptions()

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
    
    // MARK: - Private
    
    @objc private func setupEditOptions() {
        actionPanelView.layoutButton.showsMenuAsPrimaryAction = true
        actionPanelView.layoutButton.menu = AllChatsActionProvider().menu
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
