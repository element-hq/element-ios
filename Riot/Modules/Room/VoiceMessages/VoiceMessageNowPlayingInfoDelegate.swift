// 
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

@objc protocol VoiceMessageNowPlayingInfoDelegate {
    
    func updateNowPlayingInfoCenter(forPlayer player: VoiceMessageAudioPlayer)
    
    func shouldSetupRemoteCommandCenter(audioPlayer player: VoiceMessageAudioPlayer) -> Bool
    
    func shouldDisconnectFromNowPlayingInfoCenter(audioPlayer: VoiceMessageAudioPlayer) -> Bool
}
