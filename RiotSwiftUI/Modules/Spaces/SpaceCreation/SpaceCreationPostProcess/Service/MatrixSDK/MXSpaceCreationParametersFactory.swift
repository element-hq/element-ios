// 
// Copyright 2024 New Vector Ltd
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
import MatrixSDK

struct MXSpaceCreationParametersFactory {
    private let creationParams: SpaceCreationParameters
    private let parentSpaceId: String?
    private let stateEventBuilder: MXRoomInitialStateEventBuilder
    private let homeServers: [String]
    
    init(creationParams: SpaceCreationParameters, parentSpaceId: String?, stateEventBuilder: MXRoomInitialStateEventBuilder, homeServers: [String]) {
        self.creationParams = creationParams
        self.parentSpaceId = parentSpaceId
        self.stateEventBuilder = stateEventBuilder
        self.homeServers = homeServers
    }
        
    func make() -> MXSpaceCreationParameters {
        var alias = creationParams.address
        if let userDefinedAlias = creationParams.userDefinedAddress, !userDefinedAlias.isEmpty {
            alias = userDefinedAlias
        }
        let userIdInvites = creationParams.inviteType == .userId ? creationParams.userIdInvites : []
        let isPublic = creationParams.isPublic
        
        let parameters = MXSpaceCreationParameters()
        parameters.name = creationParams.name
        parameters.topic = creationParams.topic
        parameters.preset = isPublic ? kMXRoomPresetPublicChat : kMXRoomPresetPrivateChat
        parameters.visibility = isPublic ? kMXRoomDirectoryVisibilityPublic : kMXRoomDirectoryVisibilityPrivate
        parameters.inviteArray = userIdInvites
        
        if isPublic {
            parameters.roomAlias = alias
            let guestAccessStateEvent = stateEventBuilder.buildGuestAccessEvent(withAccess: .canJoin)
            parameters.addOrUpdateInitialStateEvent(guestAccessStateEvent)
            let historyVisibilityStateEvent = stateEventBuilder.buildHistoryVisibilityEvent(withVisibility: .worldReadable)
            parameters.addOrUpdateInitialStateEvent(historyVisibilityStateEvent)
            parameters.powerLevelContentOverride?.invite = 0 // default
        } else {
            parameters.powerLevelContentOverride?.invite = 50 // moderator
            
            if let parentSpaceId = parentSpaceId, creationParams.isShared {
                let guestAccessStateEvent = stateEventBuilder.buildJoinRuleEvent(withJoinRule: .restricted, allowedParentsList: [parentSpaceId])
                parameters.addOrUpdateInitialStateEvent(guestAccessStateEvent)
            }
        }
        
        return parameters
    }
}
