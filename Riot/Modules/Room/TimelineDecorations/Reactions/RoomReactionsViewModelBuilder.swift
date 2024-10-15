/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
*/

import Foundation

/// `RoomReactionsViewModelBuilder` enables to build a RoomReactionsViewModel for a given `RoomBubbleCellData` and `MXKRoomBubbleComponent` index.
@objcMembers
final class RoomReactionsViewModelBuilder: NSObject {
    
    func buildForFirstVisibleComponent(of roomBubbleCellData: RoomBubbleCellData) -> RoomReactionsViewModel? {
        
        guard roomBubbleCellData.firstVisibleComponentIndex() != NSNotFound else {
            return nil
        }
        
        return self.build(from: roomBubbleCellData, componentIndex: roomBubbleCellData.firstVisibleComponentIndex())
    }
    
    func build(from roomBubbleCellData: RoomBubbleCellData, componentIndex: Int) -> RoomReactionsViewModel? {
        
        let isCollapsableCellCollapsed = roomBubbleCellData.collapsable && roomBubbleCellData.collapsed
        
        guard isCollapsableCellCollapsed == false else {
            return nil
        }
        
        guard let bubbleComponents = roomBubbleCellData.bubbleComponents, componentIndex < roomBubbleCellData.bubbleComponents.count else {
            return nil
        }
        
        let bubbleComponent: MXKRoomBubbleComponent = bubbleComponents[componentIndex]
        
        guard let bubbleComponentEvent = bubbleComponent.event,
            bubbleComponentEvent.isRedactedEvent() == false,
            let componentEventId = bubbleComponentEvent.eventId,
            let cellDataReactions = roomBubbleCellData.reactions,
            let componentReactions = cellDataReactions[componentEventId] as? MXAggregatedReactions,
            let aggregatedReactions = componentReactions.withNonZeroCount() else {
                return nil
        }
        
        let showAllReactions = roomBubbleCellData.showAllReactions(forEvent: componentEventId)
        return RoomReactionsViewModel(aggregatedReactions: aggregatedReactions,
                                        eventId: componentEventId,
                                        showAll: showAllReactions)
    }
}
