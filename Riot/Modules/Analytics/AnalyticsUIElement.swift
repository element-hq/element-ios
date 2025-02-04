// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
    case spacePanelSwitchSubSpace
    case allChatsRecentsEnabled
    case allChatsRecentsDisabled
    case allChatsFiltersEnabled
    case allChatsFiltersDisabled
    case allChatsFilterAll
    case allChatsFilterFavourites
    case allChatsFilterUnreads
    case allChatsFilterPeople
    case spaceCreationValidated

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
        case .spacePanelSwitchSubSpace:
            return .SpacePanelSwitchSubSpace
        case .allChatsRecentsEnabled:
            return .MobileAllChatsRecentsEnabled
        case .allChatsRecentsDisabled:
            return .MobileAllChatsRecentsDisabled
        case .allChatsFiltersEnabled:
            return .MobileAllChatsFiltersEnabled
        case .allChatsFiltersDisabled:
            return .MobileAllChatsFiltersDisabled
        case .allChatsFilterAll:
            return .MobileAllChatsFilterAll
        case .allChatsFilterFavourites:
            return .MobileAllChatsFilterFavourites
        case .allChatsFilterUnreads:
            return .MobileAllChatsFilterUnreads
        case .allChatsFilterPeople:
            return .MobileAllChatsFilterPeople
        case .spaceCreationValidated:
            return .MobileSpaceCreationValidated
        }
    }
}
