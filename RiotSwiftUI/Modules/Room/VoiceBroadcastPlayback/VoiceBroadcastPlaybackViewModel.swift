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
import MatrixSDK

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
    
    init(details: VoiceBroadcastPlaybackDetails,
         mediaServiceProvider: VoiceMessageMediaServiceProvider,
         cacheManager: VoiceMessageAttachmentCacheManager,
         voiceBroadcastAggregator: VoiceBroadcastAggregator) {
        self.mediaServiceProvider = mediaServiceProvider
        self.cacheManager = cacheManager
        self.voiceBroadcastAggregator = voiceBroadcastAggregator
        
        let viewState = VoiceBroadcastPlaybackViewState(details: details,
                                                        playbackState: .stopped,
                                                        bindings: VoiceBroadcastPlaybackViewStateBindings())
        super.init(initialViewState: viewState)
        
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
        MXLog.debug("[VoiceBroadcastPlaybackViewModel] play")
        
        // TODO: But what?
        let requiredNumberOfSamples = 100// playbackView.getRequiredNumberOfSamples() ?
        
        guard let voiceBroadcast = voiceBroadcastAggregator.voiceBroadcast else {
            assert(false, "Cannot play. No voice broadcast data")
        }
        
        guard let attachment = voiceBroadcast.chunks.first?.attachment else {
            MXLog.debug("[VoiceBroadcastPlaybackViewModel] play: Error: No attachment")
            return
        }
        
        cacheManager.loadAttachment(attachment, numberOfSamples: requiredNumberOfSamples) { [weak self] result in
            
            guard let self = self else {
                return
            }
            
            switch result {
                case .success(let result):
                    guard result.eventIdentifier == attachment.eventId else {
                        return
                    }

                    // Avoid listening to old audio player delegates if the attachment for this playbackController/cell changes
                    self.audioPlayer?.deregisterDelegate(self)
                    
                    let audioPlayer = self.mediaServiceProvider.audioPlayerForIdentifier(result.eventIdentifier)
                    self.audioPlayer?.registerDelegate(self)
                    
                    audioPlayer.loadContentFromURL(result.url, displayName: attachment.originalFileName)
                    audioPlayer.play()
                    self.audioPlayer = audioPlayer
                    
                case .failure (let error):
                    MXLog.error("[VoiceBroadcastPlaybackViewModel] play: loadAttachment error", context: error)
                    self.state.playbackState = .error
            }
        }
    }
    
    /// Stop voice broadcast
    private func pause() {
        MXLog.debug("[VoiceBroadcastPlaybackViewModel] pause")
        
        guard let audioPlayer = audioPlayer else {
            return
        }
        
        if audioPlayer.isPlaying {
            audioPlayer.pause()
        }
    }
}

// MARK: - TODO: VoiceBroadcastAggregatorDelegate
extension VoiceBroadcastPlaybackViewModel: VoiceBroadcastAggregatorDelegate {
    func voiceBroadcastAggregatorDidStartLoading(_ aggregator: VoiceBroadcastAggregator) {
        MXLog.debug("AAAA voiceBroadcastAggregatorDidStartLoading")
        // TODO: VB
    }
    
    func voiceBroadcastAggregatorDidEndLoading(_ aggregator: VoiceBroadcastAggregator) {
        // TODO: VB
        MXLog.debug("AAAA voiceBroadcastAggregatorDidEndLoading")
    }
    
    func voiceBroadcastAggregator(_ aggregator: VoiceBroadcastAggregator, didFailWithError: Error) {
        // TODO: VB
        MXLog.debug("AAAA voiceBroadcastAggregatordidFailWithError")
    }
    
    func voiceBroadcastAggregatorDidUpdateData(_ aggregator: VoiceBroadcastAggregator) {
        MXLog.debug("AAAA voiceBroadcastAggregatorDidUpdateData")
    }
}


// MARK: - TODO: VoiceMessageAudioPlayerDelegate
extension VoiceBroadcastPlaybackViewModel: VoiceMessageAudioPlayerDelegate {

    
    func audioPlayerDidFinishLoading(_ audioPlayer: VoiceMessageAudioPlayer) {
    }
    
    func audioPlayerDidStartPlaying(_ audioPlayer: VoiceMessageAudioPlayer) {
        state.playbackState = .playing
    }
    
    func audioPlayerDidPausePlaying(_ audioPlayer: VoiceMessageAudioPlayer) {
        state.playbackState = .paused
    }
    
    func audioPlayerDidStopPlaying(_ audioPlayer: VoiceMessageAudioPlayer) {
        state.playbackState = .stopped
    }
    
    func audioPlayer(_ audioPlayer: VoiceMessageAudioPlayer, didFailWithError error: Error) {
        state.playbackState = .error
    }
    
    func audioPlayerDidFinishPlaying(_ audioPlayer: VoiceMessageAudioPlayer) {
        MXLog.debug("AAAA audioPlayerDidFinishPlaying")
        // TODO: but what ?
        // Chunk++
    
        //        audioPlayer.seekToTime(0.0) { [weak self] _ in
        //            guard let self = self else { return }
        //            self.state = .stopped
        //        }
    }
    
}
