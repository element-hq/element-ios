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

@objc protocol AllChatsFilterOptionsDelegate: NSObjectProtocol {
    func allChatsFilterOptions(_ allChatsFilterOptions: AllChatsFilterOptions, presentSpaceSelectorForSpacesWithIds spaceIds: [String])
    func allChatsFilterOptions(_ allChatsFilterOptions: AllChatsFilterOptions, nameForSpaceWithId spaceId: String) -> String?
}

@objcMembers
@objc class AllChatsFilterOptions: NSObject {
    weak var delegate: AllChatsFilterOptionsDelegate?
    
    func createFilterListView() -> UIView? {
        guard optionsCount > 0 else {
            return nil
        }
        
        let spaceIds = AllChatsLayoutSettingsManager.shared.allChatLayoutSettings.pinnedSpaceIds
//        let activeSpaceId = AllChatLayoutSettingsManager.shared.allChatLayoutSettings.activePinnedSpaceId
        
        var filterViews: [FilterOptionView] = []
        
        if !options.isEmpty && spaceIds.isEmpty {
            let optionView = FilterOptionView()
            optionView.isAll = true
            optionView.didTap = { optionView in
                if !optionView.isSelected {
                    Analytics.shared.trackInteraction(.allChatAllOptionActivated)
                    AllChatsLayoutSettingsManager.shared.allChatLayoutSettings.activeFilters = []
//                    self.updateActivePinnedSpace(withId: nil)
                }
            }
            filterViews.append(optionView)
        }

        if !spaceIds.isEmpty {
            let optionView = FilterOptionView()
            let pairs: [(String, String)] = spaceIds.compactMap { spaceId in
                guard let spaceName = self.delegate?.allChatsFilterOptions(self, nameForSpaceWithId: spaceId) else {
                    return nil
                }
                
                return (spaceId, spaceName)
            }
            optionView.spaceNameByIds = Dictionary(uniqueKeysWithValues: pairs)
//            if let spaceId = activeSpaceId {
//                optionView.selectedSpaceName = self.delegate?.allChatFilterOptions(self, nameForSpaceWithId: spaceId)
//            } else {
//                optionView.selectedSpaceName = nil
//            }
            optionView.didTap = { [weak self] optionView in
                guard let self = self else {
                    return
                }
                
//                if !optionView.isSelected {
                    self.delegate?.allChatsFilterOptions(self, presentSpaceSelectorForSpacesWithIds: spaceIds)
//                } else {
//                    self.updateActivePinnedSpace(withId: nil)
//                }
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
        if AllChatsLayoutSettingsManager.shared.allChatLayoutSettings.pinnedSpaceIds.isEmpty {
            return options.count
        } else {
            return options.count + 1
        }
    }
    
    func updateActivePinnedSpace(withId spaceId: String?) {
        AllChatsLayoutSettingsManager.shared.allChatLayoutSettings.activePinnedSpaceId = spaceId
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
