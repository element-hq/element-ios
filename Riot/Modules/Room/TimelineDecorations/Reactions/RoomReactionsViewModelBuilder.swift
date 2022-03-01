/*
Copyright 2020 New Vector Ltd

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
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
