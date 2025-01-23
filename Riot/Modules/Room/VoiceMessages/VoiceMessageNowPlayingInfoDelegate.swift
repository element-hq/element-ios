// 
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@objc protocol VoiceMessageNowPlayingInfoDelegate {
    
    func updateNowPlayingInfoCenter(forPlayer player: VoiceMessageAudioPlayer)
    
    func shouldSetupRemoteCommandCenter(audioPlayer player: VoiceMessageAudioPlayer) -> Bool
    
    func shouldDisconnectFromNowPlayingInfoCenter(audioPlayer: VoiceMessageAudioPlayer) -> Bool
}
