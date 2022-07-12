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
    
    static override func instantiate() -> Self {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "AllChatsViewController") as? Self else {
            fatalError("No view controller of type \(self) in the main storyboard")
        }
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.recentsTableView.tag = RecentsDataSourceMode.allChats.rawValue
    }
    
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
        vc_addFAB(withImage: Asset.Images.plusFloatingAction.image, menu: menu)
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
            RecentsDataSourceSectionType.recentRooms.rawValue
        ]
    }
}
