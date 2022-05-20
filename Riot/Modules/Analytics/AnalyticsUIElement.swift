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

import AnalyticsEvents

/// A tappable UI element that can be tracked in Analytics.
@objc enum AnalyticsUIElement: Int {
    case roomThreadListButton
    case roomThreadSummaryItem
    case threadListThreadItem
    case threadListFilterItem
    case spacePanelSelectedSpace
    case spacePanelSwitchSpace
    case editLayoutFavouritesFilterSelected
    case editLayoutFavouritesFilterUnselected
    case editLayoutFavouritesSectionSelected
    case editLayoutFavouritesSectionUnselected
    case editLayoutPeopleFilterSelected
    case editLayoutPeopleFilterUnselected
    case editLayoutRecentsSectionSelected
    case editLayoutRecentsSectionUnselected
    case editLayoutRoomsFilterSelected
    case editLayoutRoomsFilterUnselected
    case editLayoutUnreadsFilterSelected
    case editLayoutUnreadsFilterUnselected
    case allChatAllOptionActivated
    case allChatAllSpacesActivated
    case allChatFavouritesOptionActivated
    case allChatFavouritesOptionDeactivated
    case allChatPeopleOptionActivated
    case allChatPeopleOptionDeactivated
    case allChatPinnedSpaceActivated
    case allChatRoomsOptionActivated
    case allChatRoomsOptionDeactivated
    case allChatUnreadsOptionActivated
    case allChatUnreadsOptionDeactivated

    /// The element name reported to the AnalyticsEvent.
    var name: AnalyticsEvent.Interaction.Name {
        switch self {
        case .roomThreadListButton:
            return .MobileRoomThreadListButton
        case .roomThreadSummaryItem:
            return .MobileRoomThreadSummaryItem
        case .threadListThreadItem:
            return .MobileThreadListThreadItem
        case .threadListFilterItem:
            return .MobileThreadListFilterItem
        case .spacePanelSelectedSpace:
            return .SpacePanelSelectedSpace
        case .spacePanelSwitchSpace:
            return .SpacePanelSwitchSpace
        case .editLayoutFavouritesFilterSelected:
            return .EditLayoutFavouritesFilterSelected
        case .editLayoutFavouritesFilterUnselected:
            return .EditLayoutFavouritesFilterUnselected
        case .editLayoutFavouritesSectionSelected:
            return .EditLayoutFavouritesSectionSelected
        case .editLayoutFavouritesSectionUnselected:
            return .EditLayoutFavouritesSectionUnselected
        case .editLayoutPeopleFilterSelected:
            return .EditLayoutPeopleFilterSelected
        case .editLayoutPeopleFilterUnselected:
            return .EditLayoutPeopleFilterUnselected
        case .editLayoutRecentsSectionSelected:
            return .EditLayoutRecentsSectionSelected
        case .editLayoutRecentsSectionUnselected:
            return .EditLayoutRecentsSectionUnselected
        case .editLayoutRoomsFilterSelected:
            return .EditLayoutRoomsFilterSelected
        case .editLayoutRoomsFilterUnselected:
            return .EditLayoutRoomsFilterUnselected
        case .editLayoutUnreadsFilterSelected:
            return .EditLayoutUnreadsFilterSelected
        case .editLayoutUnreadsFilterUnselected:
            return .EditLayoutUnreadsFilterUnselected
        case .allChatAllOptionActivated:
            return .AllChatAllOptionActivated
        case .allChatAllSpacesActivated:
            return .AllChatAllSpacesActivated
        case .allChatFavouritesOptionActivated:
            return .AllChatFavouritesOptionActivated
        case .allChatFavouritesOptionDeactivated:
            return .AllChatFavouritesOptionDeactivated
        case .allChatPeopleOptionActivated:
            return .AllChatPeopleOptionActivated
        case .allChatPeopleOptionDeactivated:
            return .AllChatPeopleOptionDeactivated
        case .allChatPinnedSpaceActivated:
            return .AllChatPinnedSpaceActivated
        case .allChatRoomsOptionActivated:
            return .AllChatRoomsOptionActivated
        case .allChatRoomsOptionDeactivated:
            return .AllChatRoomsOptionDeactivated
        case .allChatUnreadsOptionActivated:
            return .AllChatUnreadsOptionActivated
        case .allChatUnreadsOptionDeactivated:
            return .AllChatUnreadsOptionDeactivated
        }
    }
}
