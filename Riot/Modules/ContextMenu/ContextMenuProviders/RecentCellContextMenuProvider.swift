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

@objc
protocol RecentCellContextMenuProviderDelegate: AnyObject {
    func recentCellContextMenuProviderDidStartShowingPreview(_ menuProvider: RecentCellContextMenuProvider)
}

/// Helper class `RecentCellContextMenuProvider` that provides an instace of `UIContextMenuConfiguration` from an instance of `MXKRecentCellDataStoring`
@objcMembers
class RecentCellContextMenuProvider: NSObject {

    weak var serviceDelegate: RoomContextActionServiceDelegate?
    weak var menuProviderDelegate: RecentCellContextMenuProviderDelegate?
    private var currentService: RoomContextActionServiceProtocol?
    
    @available(iOS 13.0, *)
    func contextMenuConfiguration(with cellData: MXKRecentCellDataStoring, from cell: UIView, session: MXSession) -> UIContextMenuConfiguration? {
        if cellData.isSuggestedRoom, let childInfo = cellData.roomSummary.spaceChildInfo {
            let service = UnownedRoomContextActionService(roomId: childInfo.childRoomId, canonicalAlias: childInfo.canonicalAlias, session: session, delegate: serviceDelegate)
            self.currentService = service
            let actionProvider = SpaceChildActionProvider(spaceChildInfo: childInfo, service: service)
            return UIContextMenuConfiguration(identifier: "" as NSString) {
                let viewModel = SpaceChildContextPreviewViewModel(childInfo: childInfo)
                return RoomContextPreviewViewController.instantiate(with: viewModel, mediaManager: session.mediaManager)
            } actionProvider: { suggestedActions in
                return actionProvider.menu
            }
        } else if let room = session.room(withRoomId: cellData.roomIdentifier) {
            let service = RoomContextActionService(room: room, delegate: serviceDelegate)
            self.currentService = service
            let actionProvider = RoomActionProvider(service: service)
            return UIContextMenuConfiguration(identifier: cellData.roomIdentifier as NSString) { [weak self] in
                if let self = self {
                    self.menuProviderDelegate?.recentCellContextMenuProviderDidStartShowingPreview(self)
                }
                
                if room.summary?.isJoined == true {
                    let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                    guard let roomViewController = storyboard.instantiateViewController(withIdentifier: "RoomViewControllerStoryboardId") as? RoomViewController else {
                        return nil
                    }
                    roomViewController.isContextPreview = true
                    
                    RoomPreviewDataSource.load(withRoomId: room.roomId, threadId: nil, andMatrixSession: session) { [weak roomViewController] roomDataSource in
                        guard let dataSource = roomDataSource as? RoomPreviewDataSource else {
                            return
                        }

                        dataSource.markTimelineInitialEvent = false
                        roomViewController?.displayRoom(dataSource)

                        // Give the data source ownership to the room view controller.
                        roomViewController?.hasRoomDataSourceOwnership = true
                    }

                    return roomViewController
                } else {
                    let viewModel = RoomContextPreviewViewModel(room: room)
                    return RoomContextPreviewViewController.instantiate(with: viewModel, mediaManager: session.mediaManager)
                }
            } actionProvider: { suggestedActions in
                return actionProvider.menu
            }
        }
        
        return nil
    }
    
    func roomId(from identifier: NSCopying) -> String? {
        let roomId = identifier as? String
        return roomId?.isEmpty == true ? nil : roomId
    }
}
