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

/// Helper class `BubbleCellContextMenuProvider` that provides an instace of `UIContextMenuConfiguration` from an instance of `MXKRoomBubbleCellDataStoring`
@objcMembers
class BubbleCellContextMenuProvider: NSObject {
    
    weak var serviceDelegate: RoomContextActionServiceDelegate?
    
    @available(iOS 13.0, *)
    func contextMenuConfiguration(with event: MXEvent,
                                  from cell: MXKRoomBubbleTableViewCell,
                                  at indexPath: IndexPath,
                                  session: MXSession,
                                  roomDataSource: MXKRoomDataSource,
                                  delegate: BubbleCellActionProviderDelegate?) -> UIContextMenuConfiguration? {
        guard event.eventType != .roomName, event.eventType != .roomCreate, event.eventType != .roomTag, event.eventType != .roomMember else {
            return nil
        }
        
        let actionProvider = BubbleCellActionProvider(event: event, cell: cell, session: session, roomDataSource: roomDataSource, delegate: delegate)

        return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath) {
//            return ContextMenuSnapshotPreviewViewController(view: cell.previewableView)
            return nil
        } actionProvider: { suggestedActions in
            return actionProvider.menu
        }
    }
    
    func event(from identifier: NSCopying) -> MXEvent? {
        return nil
    }
}
