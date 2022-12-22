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
import MatrixSDK

extension MXSession {
    
    /// Convenient getter to retrieve VoiceBroadcastService associated to the session
    @objc var voiceBroadcastService: VoiceBroadcastService? {
        return VoiceBroadcastServiceProvider.shared.currentVoiceBroadcastService
    }
    
    /// Initialize VoiceBroadcastService
    @objc public func getOrCreateVoiceBroadcastService(for room: MXRoom, completion: @escaping (VoiceBroadcastService?) -> Void) {
        VoiceBroadcastServiceProvider.shared.getOrCreateVoiceBroadcastService(for: room, completion: completion)
    }
    
    @objc public func tearDownVoiceBroadcastService() {
        VoiceBroadcastServiceProvider.shared.tearDownVoiceBroadcastService()
    }
    
    public func isVBRecordingInProgressFromMyAccount(roomState: MXRoomState,
                                                     stateKey: String,
                                                     startEventId: String?) -> Bool {
        return infoForVBRecordingInProgress(roomState: roomState,
                                            stateKey: stateKey,
                                            startEventId: startEventId,
                                            fromMyDevice: false) != nil
    }
    
    public func isVBRecordingInProgressFromMyDevice(roomState: MXRoomState,
                                                    stateKey: String,
                                                    startEventId: String?) -> Bool {
        return infoForVBRecordingInProgress(roomState: roomState,
                                            stateKey: stateKey,
                                            startEventId: startEventId,
                                            fromMyDevice: true) != nil
    }
    
    public func infoForVBRecordingInProgress(roomState: MXRoomState,
                                             stateKey: String,
                                             startEventId: String?,
                                             fromMyDevice: Bool) -> VoiceBroadcastInfo? {
        guard let event = validatedEvent(from: roomState, stateKey: stateKey),
              let eventDeviceId = event.content[VoiceBroadcastSettings.voiceBroadcastContentKeyDeviceId] as? String,
              self.voiceBroadcastService == nil,
              let vbInfo = validatedVoiceBroadcastInfo(from: event, startEventId: startEventId) else {
            return nil
        }
        
        if fromMyDevice, self.myDeviceId != eventDeviceId {
            return nil
        }
        
        if vbInfo.voiceBroadcastId == nil {
            vbInfo.voiceBroadcastId = event.eventId
        }
        
        return vbInfo
    }
}

private extension MXSession {
    func validatedEvent(from roomState: MXRoomState, stateKey: String) -> MXEvent? {
        guard let event = lastVoiceBroadcastStateEvent(from: roomState),
              event.stateKey == stateKey else {
            return nil
        }
        return event
    }
    
    func validatedVoiceBroadcastInfo(from event: MXEvent, startEventId: String?) -> VoiceBroadcastInfo? {
        guard let voiceBroadcastInfo = VoiceBroadcastInfo(fromJSON: event.content),
              let state = VoiceBroadcastInfoState(rawValue: voiceBroadcastInfo.state),
              state != .stopped else {
            return nil
        }
        
        if startEventId != nil,
            (event.eventId == startEventId || voiceBroadcastInfo.voiceBroadcastId == startEventId) {
            return nil
        }

        return voiceBroadcastInfo
    }
    
    func lastVoiceBroadcastStateEvent(from roomState: MXRoomState) -> MXEvent? {
        return roomState.stateEvents(with: .custom(VoiceBroadcastSettings.voiceBroadcastInfoContentKeyType))?.last
    }
}
