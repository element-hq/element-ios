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

/// this extension is temprorary and implements navigation to the Space bootom sheet. This should be moved to an universal link flow coordinator
extension RoomViewController {
    @objc func handleSpaceUniversalLink(with url: URL) {
        let url = Tools.fixURL(withSeveralHashKeys: url)
        
        var pathParams: NSArray?
        var queryParams: NSMutableDictionary?
        AppDelegate.theDelegate().parseUniversalLinkFragment(url?.fragment, outPathParams: &pathParams, outQueryParams: &queryParams)

        // Sanity check
        guard let pathParams = pathParams as? [String], pathParams.count > 0 else {
            MXLog.error("[RoomViewController] Universal link: Error: No path parameters")
            return
        }
        
        var roomIdOrAlias: String?
        var eventId: String?
        var userId: String?
        var groupId: String?
        
        // Check permalink to room or event
        if pathParams[0] == "room" && pathParams.count >= 2 {
            
            // The link is the form of "/room/[roomIdOrAlias]" or "/room/[roomIdOrAlias]/[eventId]"
            roomIdOrAlias = pathParams[1]
            
            // Is it a link to an event of a room?
            eventId = pathParams.count >= 3 ? pathParams[2] : nil
            
        } else if pathParams[0] == "group" && pathParams.count >= 2 {
            
            // The link is the form of "/group/[groupId]"
            groupId = pathParams[1]
            
        } else if (pathParams[0].hasPrefix("#") || pathParams[0].hasPrefix("!")) && pathParams.count >= 1 {
            
            // The link is the form of "/#/[roomIdOrAlias]" or "/#/[roomIdOrAlias]/[eventId]"
            // Such links come from matrix.to permalinks
            roomIdOrAlias = pathParams[0]
            eventId = pathParams.count >= 2 ? pathParams[1] : nil
            
        } else if pathParams[0] == "user" && pathParams.count == 2 { // Check permalink to a user
            // The link is the form of "/user/userId"
            userId = pathParams[1]
        } else if pathParams[0].hasPrefix("@") && pathParams.count == 1 {
            // The link is the form of "/#/[userId]"
            // Such links come from matrix.to permalinks
            userId = pathParams[0]
        }
        
        guard let roomIdOrAlias = roomIdOrAlias else {
            AppDelegate.theDelegate().handleUniversalLinkURL(url)
            return
        }
        
        self.startActivityIndicator()
        
        var viaServers: [String] = []
        if let queryParams = queryParams as? [String: Any], let via = queryParams["via"] as? [String] {
            viaServers = via
        }
        
        if roomIdOrAlias.hasPrefix("#") {
            self.mainSession.matrixRestClient.roomId(forRoomAlias: roomIdOrAlias) { [weak self] response in
                guard let self = self else {
                    return
                }
                
                guard let roomId = response.value else {
                    self.stopActivityIndicator()
                    
                    if response.error != nil {
                        let errorMessage = VectorL10n.roomDoesNotExist(roomIdOrAlias)
                        AppDelegate.theDelegate().showAlert(withTitle: nil, message: errorMessage)
                    }
                    return
                }
                
                self.requestSummaryAndShowSpaceDetail(forRoomWithId: roomId, via: viaServers, from: url)
            }
        } else {
            self.requestSummaryAndShowSpaceDetail(forRoomWithId: roomIdOrAlias, via: viaServers, from: url)
        }
    }
    
    private func requestSummaryAndShowSpaceDetail(forRoomWithId roomId: String, via: [String], from url: URL?) {
        if self.mainSession.spaceService.getSpace(withId: roomId) != nil {
            self.stopActivityIndicator()
            self.showSpaceDetail(withId: roomId)
            return
        }
        
        self.mainSession.matrixRestClient.roomSummary(with: roomId, via: via) { [weak self] response in
            guard let self = self else {
                return
            }
            
            self.stopActivityIndicator()

            guard let publicRoom = response.value, publicRoom.roomTypeString == MXRoomTypeString.space.rawValue else {
                AppDelegate.theDelegate().handleUniversalLinkURL(url)
                return
            }
            
            self.showSpaceDetail(with: publicRoom)
        }
    }
    
}
