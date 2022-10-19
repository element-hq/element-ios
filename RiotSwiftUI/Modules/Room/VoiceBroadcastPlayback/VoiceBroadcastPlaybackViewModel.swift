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

import Combine
import SwiftUI

typealias VoiceBroadcastPlaybackViewModelType = StateStoreViewModel<VoiceBroadcastPlaybackViewState, VoiceBroadcastPlaybackViewAction>

class VoiceBroadcastPlaybackViewModel: VoiceBroadcastPlaybackViewModelType, VoiceBroadcastPlaybackViewModelProtocol {

    // MARK: - Properties

    // MARK: Private
    private var voiceBroadcastAggregator: VoiceBroadcastAggregator
    private let mediaServiceProvider: VoiceMessageMediaServiceProvider
    private let cacheManager: VoiceMessageAttachmentCacheManager
    private var audioPlayer: VoiceMessageAudioPlayer?
    
    // MARK: Public
    
    // MARK: - Setup
    
    init(mediaServiceProvider: VoiceMessageMediaServiceProvider,
         cacheManager: VoiceMessageAttachmentCacheManager,
         voiceBroadcastAggregator: VoiceBroadcastAggregator) {
        self.mediaServiceProvider = mediaServiceProvider
        self.cacheManager = cacheManager
        self.voiceBroadcastAggregator = voiceBroadcastAggregator
        
        let voiceBroadcastPlaybackDetails = VoiceBroadcastPlaybackDetails(type: VoiceBroadcastPlaybackType.player, chunks: [])
        super.init(initialViewState: VoiceBroadcastPlaybackViewState(voiceBroadcast: voiceBroadcastPlaybackDetails, bindings: VoiceBroadcastPlaybackViewStateBindings()))
        
        self.voiceBroadcastAggregator.delegate = self
    }
    
    // MARK: - Public
    
    override func process(viewAction: VoiceBroadcastPlaybackViewAction) {
        switch viewAction {
        case .play:
            play()
        case .pause:
            pause()
        }
    }
    
    /// Listen voice broadcast
    private func play() {
        // TODO: VB call voice broadcast playback service to play the chunks
    }
    
    /// Stop voice broadcast
    private func pause() {
    }
    
    // MARK: - VoiceBroadcastPlaybackViewModelProtocol
    
    func updateWithVoiceBroadcastDetails(_ voiceBroadcastDetails: VoiceBroadcastPlaybackDetails) {
        state.voiceBroadcast = voiceBroadcastDetails
    }
}

extension VoiceBroadcastPlaybackViewModel: VoiceBroadcastAggregatorDelegate {
    func voiceBroadcastAggregatorDidStartLoading(_ aggregator: VoiceBroadcastAggregator) {
        // TODO: VB
    }
    
    func voiceBroadcastAggregatorDidEndLoading(_ aggregator: VoiceBroadcastAggregator) {
        // TODO: VB
    }
    
    func voiceBroadcastAggregator(_ aggregator: VoiceBroadcastAggregator, didFailWithError: Error) {
        // TODO: VB
    }
    
    func voiceBroadcastAggregatorDidUpdateData(_ aggregator: VoiceBroadcastAggregator) {
        let voiceBroadcastPlaybackDetails = VoiceBroadcastPlaybackDetails(type: .player, chunks: Array(aggregator.voiceBroadcast.chunks))
        self.updateWithVoiceBroadcastDetails(voiceBroadcastPlaybackDetails)
    }
}
