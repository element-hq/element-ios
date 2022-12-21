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

extension MXRoomState {
    func cancelCurrentVoiceBroadcastRecordingIfNeeded(for room: MXRoom, session: MXSession) {
        /// Detection of a potential unfinished VoiceBroadcast
        /// Check whether a VoiceBroadcast is in progress on the current session for this room whereas no VoiceBroadcast Service is available.
        guard let event = self.stateEvents(with: .custom(VoiceBroadcastSettings.voiceBroadcastInfoContentKeyType))?.last,
              event.stateKey == session.myUserId,
              let eventDeviceId = event.content[VoiceBroadcastSettings.voiceBroadcastContentKeyDeviceId] as? String,
              session.myDeviceId == eventDeviceId,
              let voiceBroadcastInfo = VoiceBroadcastInfo(fromJSON: event.content),
              let state = VoiceBroadcastInfoState(rawValue: voiceBroadcastInfo.state),
              state != .stopped,
              session.voiceBroadcastService == nil else {
            return
        }
        
        session.getOrCreateVoiceBroadcastService(for: room) { service in
            guard let vbService = service else {
                return
            }

            vbService.stopVoiceBroadcast(lastChunkSequence: 0,
                                         voiceBroadcastId: event.eventId) { response in
                MXLog.debug("[MXRoomState] cancelCurrentVoiceBroadcastRecordingIfNeeded stopVoiceBroadcast with response : \(response)")
                session.tearDownVoiceBroadcastService()
            }
        }
    }
}
