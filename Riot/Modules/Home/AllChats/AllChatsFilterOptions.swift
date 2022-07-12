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

@objcMembers
@objc class AllChatsFilterOptions: NSObject {

    func createFilterListView() -> UIView? {
        guard optionsCount > 0 else {
            return nil
        }
        
        var filterViews: [FilterOptionView] = []
        
        if !options.isEmpty {
            let optionView = FilterOptionView()
            optionView.isAll = true
            optionView.didTap = { optionView in
                if !optionView.isSelected {
                    Analytics.shared.trackInteraction(.allChatAllOptionActivated)
                    AllChatsLayoutSettingsManager.shared.allChatLayoutSettings.activeFilters = []
                }
            }
            filterViews.append(optionView)
        }
        
        for option in options {
            let optionView = FilterOptionView()
            optionView.data = option
            optionView.didTap = { [weak self] optionView in
                self?.trackSelectionChangeFor(optionView)
                
                if !optionView.isSelected {
                    AllChatsLayoutSettingsManager.shared.allChatLayoutSettings.activeFilters = option.type
                } else {
                    AllChatsLayoutSettingsManager.shared.allChatLayoutSettings.activeFilters.remove(option.type)
                }
            }
            filterViews.append(optionView)
        }
        
        let filterOptionListView = FilterOptionListView()
        filterOptionListView.filterViews = filterViews

        return filterOptionListView
    }
    
    private func trackSelectionChangeFor(_ optionView: FilterOptionView) {
        guard let optionType = optionView.data?.type else {
            return
        }
        
        switch optionType {
        case .favourites:
            Analytics.shared.trackInteraction(optionView.isSelected ? .allChatFavouritesOptionDeactivated : .allChatFavouritesOptionActivated)
        case .people:
            Analytics.shared.trackInteraction(optionView.isSelected ? .allChatPeopleOptionDeactivated : .allChatPeopleOptionActivated)
        case .rooms:
            Analytics.shared.trackInteraction(optionView.isSelected ? .allChatRoomsOptionDeactivated : .allChatRoomsOptionActivated)
        case .unreads:
            Analytics.shared.trackInteraction(optionView.isSelected ? .allChatUnreadsOptionDeactivated : .allChatUnreadsOptionActivated)
        default: break
        }
    }
    
    var optionsCount: Int {
        return options.count
    }
    
    private var options: [AllChatsLayoutEditorFilter] {
        var options: [AllChatsLayoutEditorFilter] = []
        let filters = AllChatsLayoutSettingsManager.shared.allChatLayoutSettings.filters
        let activeFilters = AllChatsLayoutSettingsManager.shared.allChatLayoutSettings.activeFilters
        if filters.contains(.people) {
            options.append(AllChatsLayoutEditorFilter(type: .people,
                                                     name: VectorL10n.titlePeople,
                                                     image: Asset.Images.tabPeople.image,
                                                     selected: activeFilters.contains(.people)))
        }
        if filters.contains(.rooms) {
            options.append(AllChatsLayoutEditorFilter(type: .rooms,
                                                     name: VectorL10n.titleRooms,
                                                     image: Asset.Images.tabRooms.image,
                                                     selected: activeFilters.contains(.rooms)))
        }
        if filters.contains(.favourites) {
            options.append(AllChatsLayoutEditorFilter(type: .favourites,
                                                     name: VectorL10n.titleFavourites,
                                                     image: Asset.Images.tabFavourites.image,
                                                     selected: activeFilters.contains(.favourites)))
        }
        if filters.contains(.unreads) {
            options.append(AllChatsLayoutEditorFilter(type: .unreads,
                                                     name: VectorL10n.allChatsEditLayoutUnreads,
                                                     image: Asset.Images.allChatUnreads.image,
                                                     selected: activeFilters.contains(.unreads)))
        }
        return options
    }
}
