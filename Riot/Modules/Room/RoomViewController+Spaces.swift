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
    
    @objc func handleSpaceUniversalLink(with universalLinkParameters: UniversalLinkParameters) -> Bool {
        
        let url = universalLinkParameters.universalLinkURL
        
        var pathParamsObjc: NSArray?
        var queryParamsObjc: NSMutableDictionary?
        AppDelegate.theDelegate().parseUniversalLinkFragment(url?.fragment, outPathParams: &pathParamsObjc, outQueryParams: &queryParamsObjc)

        // Sanity check
        guard let pathParams = pathParamsObjc as? [String], pathParams.count > 0 else {
            MXLog.error("[RoomViewController] Universal link: Error: No path parameters")
            return false
        }
        
        var roomIdOrAliasParam: String?
        var eventIdParam: String?
        var userIdParam: String?
        var groupIdParam: String?
        
        // Check permalink to room or event
        if pathParams[0] == "room" && pathParams.count >= 2 {
            
            // The link is the form of "/room/[roomIdOrAlias]" or "/room/[roomIdOrAlias]/[eventId]"
            roomIdOrAliasParam = pathParams[1]
            
            // Is it a link to an event of a room?
            eventIdParam = pathParams.count >= 3 ? pathParams[2] : nil
            
        } else if pathParams[0] == "group" && pathParams.count >= 2 {
            
            // The link is the form of "/group/[groupId]"
            groupIdParam = pathParams[1]
            
        } else if (pathParams[0].hasPrefix("#") || pathParams[0].hasPrefix("!")) && pathParams.count >= 1 {
            
            // The link is the form of "/#/[roomIdOrAlias]" or "/#/[roomIdOrAlias]/[eventId]"
            // Such links come from matrix.to permalinks
            roomIdOrAliasParam = pathParams[0]
            eventIdParam = pathParams.count >= 2 ? pathParams[1] : nil
            
        } else if pathParams[0] == "user" && pathParams.count == 2 { // Check permalink to a user
            // The link is the form of "/user/userId"
            userIdParam = pathParams[1]
        } else if pathParams[0].hasPrefix("@") && pathParams.count == 1 {
            // The link is the form of "/#/[userId]"
            // Such links come from matrix.to permalinks
            userIdParam = pathParams[0]
        }
        
        guard let roomIdOrAlias = roomIdOrAliasParam else {
            return AppDelegate.theDelegate().handleUniversalLink(with: universalLinkParameters)
        }
        
        self.startActivityIndicator()
        
        var viaServers: [String] = []
        if let queryParams = queryParamsObjc as? [String: Any], let via = queryParams["via"] as? [String] {
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
                
                self.requestSummaryAndShowSpaceDetail(forRoomWithId: roomId, via: viaServers, from: universalLinkParameters)
            }
        } else {
            self.requestSummaryAndShowSpaceDetail(forRoomWithId: roomIdOrAlias, via: viaServers, from: universalLinkParameters)
        }
        
        return true
    }
    
    private func requestSummaryAndShowSpaceDetail(forRoomWithId roomId: String, via: [String], from universalLinkParameters: UniversalLinkParameters) {
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
                AppDelegate.theDelegate().handleUniversalLink(with: universalLinkParameters)
                return
            }
            
            self.showSpaceDetail(with: publicRoom)
        }
    }
}
