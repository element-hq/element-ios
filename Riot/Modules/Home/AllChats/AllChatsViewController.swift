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
    
    @IBOutlet private weak var toolbar: UIToolbar!
    
    private let searchController = UISearchController(searchResultsController: nil)
    
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
        
        self.tabBarController?.title = VectorL10n.allChatsTitle
        vc_setLargeTitleDisplayMode(.automatic)

        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self

        NotificationCenter.default.addObserver(self, selector: #selector(self.setupEditOptions), name: AllChatsLayoutSettingsManager.didUpdateSettings, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        toolbar.tintColor = ThemeService.shared().theme.colors.accent
        if self.tabBarController?.navigationItem.searchController == nil {
            self.tabBarController?.navigationItem.searchController = searchController
        }
    }
    
    // MARK: - HomeViewController
    
    override var recentsDataSourceMode: RecentsDataSourceMode {
        .allChats
    }
    
    @objc private func addFabButton() {
        self.setupEditOptions()
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
    
    // MARK: - Private
    
    @objc private func setupEditOptions() {
        // Note: updating toolbar items doesn't work as expected and has weird behaviour
        // Also this piece of code is going to be updated in the next PR
        
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
        
        toolbar.items = [
            UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), menu: AllChatsActionProvider().menu),
            UIBarButtonItem.flexibleSpace(),
            UIBarButtonItem(image: UIImage(systemName: "square.and.pencil"), menu: editMenu)
        ]
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
