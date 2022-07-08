// 
// Copyright 2021 New Vector Ltd
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
import Combine

@available(iOS 14.0, *)
class AllChatsLayoutEditorService: AllChatsLayoutEditorServiceProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let settings: AllChatsLayoutSettings

    // MARK: Public
    
    var sections: [AllChatsLayoutEditorSection] {
        [
            AllChatsLayoutEditorSection(type: .recents, name: VectorL10n.allChatsEditLayoutRecents, image: Asset.Images.allChatRecents.image, selected: settings.sections.contains(.recents)),
            AllChatsLayoutEditorSection(type: .favourites, name: VectorL10n.titleFavourites, image: Asset.Images.tabFavourites.image, selected: settings.sections.contains(.favourites))
        ]
    }
    
    var filters: [AllChatsLayoutEditorFilter] {
        [
            AllChatsLayoutEditorFilter(type: .people, name: VectorL10n.titlePeople, image: Asset.Images.tabPeople.image, selected: settings.filters.contains(.people)),
            AllChatsLayoutEditorFilter(type: .rooms, name: VectorL10n.titleRooms, image: Asset.Images.tabRooms.image, selected: settings.filters.contains(.rooms)),
            AllChatsLayoutEditorFilter(type: .favourites, name: VectorL10n.titleFavourites, image: Asset.Images.tabFavourites.image, selected: settings.filters.contains(.favourites)),
            AllChatsLayoutEditorFilter(type: .unreads, name: VectorL10n.allChatsEditLayoutUnreads, image: Asset.Images.allChatUnreads.image, selected: settings.filters.contains(.unreads)),
        ]
    }
    
    var sortingOptions: [AllChatsLayoutEditorSortingOption] {
        [
            AllChatsLayoutEditorSortingOption(type: .activity, name: VectorL10n.allChatsEditLayoutActivityOrder, selected: settings.sorting == .activity),
            AllChatsLayoutEditorSortingOption(type: .alphabetical, name: VectorL10n.allChatsEditLayoutAlphabeticalOrder, selected: settings.sorting == .alphabetical)
        ]
    }
    
    var pinnedSpaces: [SpaceSelectorListItemData] {
        settings.pinnedSpaceIds.compactMap { spaceId in
            guard let summary = session.roomSummary(withRoomId: spaceId) else {
                return nil
            }
            
            return SpaceSelectorListItemData(id: spaceId, avatar: summary.room.avatarData, icon: nil, displayName: summary.displayname)
        }
    }

    // MARK: - Setup
    
    init(session: MXSession,
         settings: AllChatsLayoutSettings) {
        self.session = session
        self.settings = settings
    }
    
    // MARK: - Public
    
    func trackDoneAction(sections: [AllChatsLayoutEditorSection],
                         filters: [AllChatsLayoutEditorFilter],
                         sortingOptions: [AllChatsLayoutEditorSortingOption],
                         pinnedSpaces: [SpaceSelectorListItemData]) {
        for section in sections {
            switch section.type {
            case .favourites:
                trackChangeFor(section: section, selectedEvent: .editLayoutFavouritesSectionSelected, unselectedEvent: .editLayoutFavouritesSectionUnselected)
            case .recents:
                trackChangeFor(section: section, selectedEvent: .editLayoutRecentsSectionSelected, unselectedEvent: .editLayoutRecentsSectionUnselected)
            default:
                break
            }
        }
        
        for filter in filters {
            switch filter.type {
            case .favourites:
                trackChangeFor(filter: filter, selectedEvent: .editLayoutFavouritesFilterSelected, unselectedEvent: .editLayoutFavouritesFilterUnselected)
            case .people:
                trackChangeFor(filter: filter, selectedEvent: .editLayoutPeopleFilterSelected, unselectedEvent: .editLayoutPeopleFilterUnselected)
            case .rooms:
                trackChangeFor(filter: filter, selectedEvent: .editLayoutRoomsFilterSelected, unselectedEvent: .editLayoutRoomsFilterUnselected)
            case .unreads:
                trackChangeFor(filter: filter, selectedEvent: .editLayoutUnreadsFilterSelected, unselectedEvent: .editLayoutUnreadsFilterUnselected)
            default:
                break
            }
        }
        
        Analytics.shared.trackEditLayoutPinnedSpaces(with: pinnedSpaces.count)
    }
    
    func outputSettings(sections: [AllChatsLayoutEditorSection],
                        filters: [AllChatsLayoutEditorFilter],
                        sortingOptions: [AllChatsLayoutEditorSortingOption],
                        pinnedSpaces: [SpaceSelectorListItemData]) -> AllChatsLayoutSettings {
        let sections: AllChatsLayoutSectionType = AllChatsLayoutSectionType(rawValue: sections.reduce(0, { $1.selected ? $0 | $1.type.rawValue : $0 }))
        let filters: AllChatsLayoutFilterType = AllChatsLayoutFilterType(rawValue: filters.reduce(0, { $1.selected ? $0 | $1.type.rawValue : $0 }))
        let sorting: AllChatsLayoutSortingType = sortingOptions.first(where: { $0.selected })?.type ?? .activity
        let pinnedSpaceIds: [String] = pinnedSpaces.map{ $0.id }
        let settings = AllChatsLayoutSettings(sections: sections, filters: filters, sorting: sorting, pinnedSpaceIds: pinnedSpaceIds)
        settings.activeFilters = self.settings.activeFilters
        return settings
    }
    
    // MARK: - Private
    
    private func trackChangeFor(section: AllChatsLayoutEditorSection, selectedEvent: AnalyticsUIElement, unselectedEvent: AnalyticsUIElement) {
        if section.selected && !settings.sections.contains(section.type) {
            MXLog.debug("[AllChatLayoutEditorService] tracking \(selectedEvent.name)")
            Analytics.shared.trackInteraction(selectedEvent)
        } else if !section.selected && settings.sections.contains(section.type) {
            MXLog.debug("[AllChatLayoutEditorService] tracking \(unselectedEvent.name)")
            Analytics.shared.trackInteraction(unselectedEvent)
        }
    }
    
    private func trackChangeFor(filter: AllChatsLayoutEditorFilter, selectedEvent: AnalyticsUIElement, unselectedEvent: AnalyticsUIElement) {
        if filter.selected && !settings.filters.contains(filter.type) {
            MXLog.debug("[AllChatLayoutEditorService] tracking \(selectedEvent.name)")
            Analytics.shared.trackInteraction(selectedEvent)
        } else if !filter.selected && settings.filters.contains(filter.type) {
            MXLog.debug("[AllChatLayoutEditorService] tracking \(unselectedEvent.name)")
            Analytics.shared.trackInteraction(unselectedEvent)
        }
    }
}
