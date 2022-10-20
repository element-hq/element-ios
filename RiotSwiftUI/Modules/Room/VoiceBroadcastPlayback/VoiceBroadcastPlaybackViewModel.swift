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
    
    private var voiceBroadcastChunkQueue: [VoiceBroadcastChunk] = []
    
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
        if voiceBroadcastAggregator.isStarted == false {
            // Start the streaming by fetching broadcast chunks
            // The audio player will start the automatically playback on incoming chunks
            MXLog.debug("[VoiceBroadcastPlaybackViewModel] play: Start streaming")
            state.playbackState = .buffering
            voiceBroadcastAggregator.start()
        }
        else if let audioPlayer = audioPlayer {
            // Streaming is already up. Just resume or restart after stop
            // TODO: Does not work
            MXLog.debug("[VoiceBroadcastPlaybackViewModel] play: audioPlayer.play()")
            audioPlayer.play()
        }
        else {
            MXLog.error("[VoiceBroadcastPlaybackViewModel] play: Unexpected state")
        }
    }
    
    /// Stop voice broadcast
    private func pause() {
        MXLog.debug("[VoiceBroadcastPlaybackViewModel] pause")
        
        if let audioPlayer = audioPlayer, audioPlayer.isPlaying {
            audioPlayer.pause()
        }
    }
    
    
    func processNextVoiceBroadcastChunk() {
        
        MXLog.debug("[VoiceBroadcastPlaybackViewModel] processNextVoiceBroadcastChunk: \(voiceBroadcastChunkQueue.count) chunks remaining")
        
        guard voiceBroadcastChunkQueue.count > 0 else {
            // We cached all chunks. Nothing more to do
            return
        }
        
        let chunk = voiceBroadcastChunkQueue.removeFirst()
        
        // numberOfSamples is for the equalizer view we do not support yet
        cacheManager.loadAttachment(chunk.attachment, numberOfSamples: 1) { [weak self] result in
            
            // TODO: Make sure there has no new incoming chunk that should be before this attachment
            
            guard let self = self else {
                return
            }
            
            switch result {
                case .success(let result):
                    guard result.eventIdentifier == chunk.attachment.eventId else {
                        return
                    }
                    
                    if self.audioPlayer == nil {
                        // Init and start the player on the first chunk
                        let audioPlayer = self.mediaServiceProvider.audioPlayerForIdentifier(result.eventIdentifier)
                        audioPlayer.registerDelegate(self)
                        
                        audioPlayer.loadContentFromURL(result.url, displayName: chunk.attachment.originalFileName)
                        audioPlayer.play()
                        self.audioPlayer = audioPlayer
                    }
                    else {
                        // Append the chunk to the current playlist
                        self.audioPlayer?.addContentFromURL(result.url)
                    }

                case .failure (let error):
                    MXLog.error("[VoiceBroadcastPlaybackViewModel] processVoiceBroadcastChunkQueue: loadAttachment error", context: error)
                    if self.voiceBroadcastChunkQueue.count == 0 {
                        // No more chunk to try. Go to error
                        self.state.playbackState = .error
                    }
            }
            
            // TODO: Throttle to avoid to download all chunk in mass
            self.processNextVoiceBroadcastChunk()
        }
    }
}

// MARK: - TODO: VoiceBroadcastAggregatorDelegate
extension VoiceBroadcastPlaybackViewModel: VoiceBroadcastAggregatorDelegate {
    func voiceBroadcastAggregatorDidStartLoading(_ aggregator: VoiceBroadcastAggregator) {
    }
    
    func voiceBroadcastAggregatorDidEndLoading(_ aggregator: VoiceBroadcastAggregator) {
    }
    
    func voiceBroadcastAggregator(_ aggregator: VoiceBroadcastAggregator, didFailWithError: Error) {
        MXLog.error("[VoiceBroadcastPlaybackViewModel] voiceBroadcastAggregator didFailWithError:", context: didFailWithError)
    }
    
    func voiceBroadcastAggregator(_ aggregator: VoiceBroadcastAggregator, didReceiveChunk: VoiceBroadcastChunk) {
        voiceBroadcastChunkQueue.append(didReceiveChunk)
    }
    
    func voiceBroadcastAggregatorDidUpdateData(_ aggregator: VoiceBroadcastAggregator) {
        // Make sure we download and process check in the right order
        voiceBroadcastChunkQueue = voiceBroadcastChunkQueue.sorted(by: {$0.sequence < $1.sequence})
        
        self.processNextVoiceBroadcastChunk()
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
//        audioPlayer.seekToTime(0.0) { [weak self] _ in
//            guard let self = self else { return }
//            self.state.playbackState = .stopped
//            audioPlayer.stop()
//        }
    }
    
}
