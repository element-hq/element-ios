// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Helper class `PublicRoomContextMenuProvider` that provides an instace of `UIContextMenuConfiguration` from an instance of `MXPublicRoom`
@objcMembers
class PublicRoomContextMenuProvider: NSObject {
    
    weak var serviceDelegate: RoomContextActionServiceDelegate?
    private var currentService: RoomContextActionServiceProtocol?
    
    @available(iOS 13.0, *)
    func contextMenuConfiguration(with publicRoom: MXPublicRoom, from cell: UIView, session: MXSession) -> UIContextMenuConfiguration? {
        if let room = session.room(withRoomId: publicRoom.roomId) {
            let service = RoomContextActionService(room: room, delegate: serviceDelegate)
            self.currentService = service
            let actionProvider = RoomActionProvider(service: service)
            return UIContextMenuConfiguration(identifier: publicRoom.jsonString() as? NSString) {
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
        } else {
            let service = UnownedRoomContextActionService(roomId: publicRoom.roomId, canonicalAlias: publicRoom.canonicalAlias, session: session, delegate: serviceDelegate)
            self.currentService = service
            let actionProvider = PublicRoomActionProvider(publicRoom: publicRoom, service: service)
            return UIContextMenuConfiguration(identifier: publicRoom.jsonString() as? NSString) {
                let viewModel = PublicRoomContextPreviewViewModel(publicRoom: publicRoom)
                return RoomContextPreviewViewController.instantiate(with: viewModel, mediaManager: session.mediaManager)
            } actionProvider: { suggestedActions in
                return actionProvider.menu
            }
        }
    }
    
    func publicRoom(from identifier: NSCopying) -> MXPublicRoom? {
        guard let jsonString = identifier as? String, let data = jsonString.data(using: .utf8) else {
            return nil
        }

        do {
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            
            guard let publicRoom = MXPublicRoom(fromJSON: json) else {
                return nil
            }

            return publicRoom
        } catch {
            return nil
        }
    }
}
