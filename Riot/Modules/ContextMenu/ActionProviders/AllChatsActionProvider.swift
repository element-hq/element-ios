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

import Foundation
import UIKit

/// `AllChatsActionProvider` provides the menu for managing the `AllChatsLayoutSettingsManager`
@available(iOS 13.0, *)
class AllChatsActionProvider {
    
    // MARK: - Properties
    
    private let allChatsSettingsManager = AllChatsLayoutSettingsManager.shared
    
    // MARK: - RoomActionProviderProtocol
    
    var menu: UIMenu {
        return UIMenu(title: "", children: [
            self.recentsAction,
            self.filtersAction,
            UIMenu(title: "", options: .displayInline, children: [
                activityOrderAction,
                alphabeticalOrderAction
            ])
        ])
    }
    
    // MARK: - Private
    
    private var recentsAction: UIAction {
        return UIAction(title: VectorL10n.allChatsEditLayoutShowRecents,
                        image: UIImage(systemName: "clock.arrow.circlepath")?.withRenderingMode(.alwaysTemplate),
                        discoverabilityTitle: VectorL10n.allChatsEditLayoutShowRecents,
                        state: AllChatsLayoutSettingsManager.shared.allChatLayoutSettings.sections.contains(.recents) ? .on : .off) { action in
                            let settings = AllChatsLayoutSettingsManager.shared.allChatLayoutSettings
                            let newSettings = AllChatsLayoutSettings(sections: action.state == .on ? [] : .recents,
                                                                     filters: settings.filters,
                                                                     sorting: settings.sorting)
                            AllChatsLayoutSettingsManager.shared.allChatLayoutSettings = newSettings
                            Analytics.shared.trackInteraction(action.state == .on ? .allChatsRecentsDisabled : .allChatsRecentsEnabled)
                        }
    }
    
    private var filtersAction: UIAction {
        return UIAction(title: VectorL10n.allChatsEditLayoutShowFilters,
                        image: UIImage(systemName: "bubble.right")?.withRenderingMode(.alwaysTemplate),
                        state: AllChatsLayoutSettingsManager.shared.allChatLayoutSettings.filters == [] ? .off : .on) { action in
                            let settings = AllChatsLayoutSettingsManager.shared.allChatLayoutSettings
                            let newSettings = AllChatsLayoutSettings(sections: settings.sections,
                                                                     filters: action.state == .on ? [] : [.unreads, .favourites, .people],
                                                                     sorting: settings.sorting)
                            AllChatsLayoutSettingsManager.shared.allChatLayoutSettings = newSettings
                            Analytics.shared.trackInteraction(action.state == .on ? .allChatsFiltersDisabled : .allChatsFiltersEnabled)
                        }
    }
    
    private var activityOrderAction: UIAction {
        return UIAction(title: VectorL10n.allChatsEditLayoutActivityOrder,
                        state: AllChatsLayoutSettingsManager.shared.allChatLayoutSettings.sorting == .activity ? .on : .off) { action in
                            let settings = AllChatsLayoutSettingsManager.shared.allChatLayoutSettings
                            let newSettings = AllChatsLayoutSettings(sections: settings.sections,
                                                                     filters: settings.filters,
                                                                     sorting: .activity)
                            AllChatsLayoutSettingsManager.shared.allChatLayoutSettings = newSettings
                        }
    }
    
    private var alphabeticalOrderAction: UIAction {
        return UIAction(title: VectorL10n.allChatsEditLayoutAlphabeticalOrder,
                        state: AllChatsLayoutSettingsManager.shared.allChatLayoutSettings.sorting == .alphabetical ? .on : .off) { action in
                            let settings = AllChatsLayoutSettingsManager.shared.allChatLayoutSettings
                            let newSettings = AllChatsLayoutSettings(sections: settings.sections,
                                                                     filters: settings.filters,
                                                                     sorting: .alphabetical)
                            AllChatsLayoutSettingsManager.shared.allChatLayoutSettings = newSettings
                        }
    }
}
