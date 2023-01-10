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
