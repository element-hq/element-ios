// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import MatrixSDK

extension MXRoom {
    
    func stopUncompletedVoiceBroadcastIfNeeded() {
        // Detection of a potential uncompleted VoiceBroadcast
        // Check whether a VoiceBroadcast is in progress on the current session for this room whereas no VoiceBroadcast Service is available.
        self.lastVoiceBroadcastStateEvent { event in
            guard let event = event,
                  event.stateKey == self.mxSession.myUserId,
                  let eventDeviceId = event.content[VoiceBroadcastSettings.voiceBroadcastContentKeyDeviceId] as? String,
                  eventDeviceId == self.mxSession.myDeviceId,
                  let voiceBroadcastInfo = VoiceBroadcastInfo(fromJSON: event.content),
                  voiceBroadcastInfo.state != VoiceBroadcastInfoState.stopped.rawValue,
                  self.mxSession.voiceBroadcastService == nil else {
                return
            }
            
            self.mxSession.getOrCreateVoiceBroadcastService(for: self) { service in
                guard let service = service else {
                    return
                }
                
                service.stopVoiceBroadcast(lastChunkSequence: 0,
                                             voiceBroadcastId: voiceBroadcastInfo.voiceBroadcastId ?? event.eventId) { response in
                    MXLog.debug("[MXRoom] stopUncompletedVoiceBroadcastIfNeeded stopVoiceBroadcast with response : \(response)")
                    self.mxSession.tearDownVoiceBroadcastService()
                }
            }
        }
    }
    
    func lastVoiceBroadcastStateEvent(completion: @escaping (MXEvent?) -> Void) {
        self.state { roomState in
            completion(roomState?.stateEvents(with: .custom(VoiceBroadcastSettings.voiceBroadcastInfoContentKeyType))?.last)
        }
    }
}
