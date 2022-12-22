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

import MatrixSDK

extension MXRoom {
    @objc public func isVoiceBroadcastRecordingInProgressFromMyDevice(completion: @escaping (Bool) -> Void) {
        isVoiceBroadcastRecordingInProgress(fromMyDevice: true, completion: completion)
    }
    
    @objc public func isVoiceBroadcastRecordingInProgressFromMyAccount(completion: @escaping (Bool) -> Void) {
        isVoiceBroadcastRecordingInProgress(fromMyDevice: false, completion: completion)
    }
    
    @objc public func infoForVBRecordingInProgress(roomState: MXRoomState,
                                                   stateKey: String?,
                                                   startEventId: String?,
                                                   fromMyDevice: Bool) -> VoiceBroadcastInfo? {
        guard let event = validatedEvent(from: roomState, stateKey: stateKey),
              let eventDeviceId = event.content[VoiceBroadcastSettings.voiceBroadcastContentKeyDeviceId] as? String,
              mxSession.voiceBroadcastService == nil,
              let vbInfo = validatedVoiceBroadcastInfo(from: event, startEventId: startEventId) else {
            return nil
        }
        
        if fromMyDevice, mxSession.myDeviceId != eventDeviceId {
            return nil
        }
        
        if vbInfo.voiceBroadcastId == nil {
            vbInfo.voiceBroadcastId = event.eventId
        }
        
        return vbInfo
    }
}

private extension MXRoom {
    @objc func isVoiceBroadcastRecordingInProgress(fromMyDevice: Bool,
                                                          completion: @escaping (Bool) -> Void) {
        self.state { [weak self] roomState in
            guard let self = self,
                  let roomState = roomState,
                  let vbInfo = self.infoForVBRecordingInProgress(roomState: roomState,
                                                                 stateKey: nil,
                                                                 startEventId: nil,
                                                                 fromMyDevice: fromMyDevice) else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    func validatedEvent(from roomState: MXRoomState, stateKey: String?) -> MXEvent? {
        guard let event = lastVoiceBroadcastStateEvent(from: roomState) else {
            return nil
        }
        
        if stateKey != nil, event.stateKey != stateKey {
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
