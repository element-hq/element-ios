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

// TODO: VoiceBroadcastPlaybackViewModel must be revisited in order to not depend on MatrixSDK
// We need a VoiceBroadcastPlaybackServiceProtocol and VoiceBroadcastAggregatorProtocol
import MatrixSDK

class VoiceBroadcastPlaybackViewModel: VoiceBroadcastPlaybackViewModelType, VoiceBroadcastPlaybackViewModelProtocol {

    // MARK: - Properties

    // MARK: Private
    private let mediaServiceProvider: VoiceMessageMediaServiceProvider
    private let cacheManager: VoiceMessageAttachmentCacheManager
    
    private var voiceBroadcastAggregator: VoiceBroadcastAggregator
    private var voiceBroadcastChunkQueue: [VoiceBroadcastChunk] = []
    private var voiceBroadcastAttachmentCacheManagerLoadResults: [VoiceMessageAttachmentCacheManagerLoadResult] = []
    
    private var audioPlayer: VoiceMessageAudioPlayer?
    private var displayLink: CADisplayLink!
    
    private var isLivePlayback = false
    private var acceptProgressUpdates = true
    
    private var isActuallyPaused: Bool = false
    
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
                                                        broadcastState: VoiceBroadcastPlaybackViewModel.getBroadcastState(from: voiceBroadcastAggregator.voiceBroadcastState),
                                                        playbackState: .stopped,
                                                        playingState: VoiceBroadcastPlayingState(duration: Float(voiceBroadcastAggregator.voiceBroadcast.duration)),
                                                        bindings: VoiceBroadcastPlaybackViewStateBindings(progress: 0))
        super.init(initialViewState: viewState)
        
        displayLink = CADisplayLink(target: WeakTarget(self, selector: #selector(handleDisplayLinkTick)), selector: WeakTarget.triggerSelector)
        displayLink.isPaused = true
        displayLink.add(to: .current, forMode: .common)
        
        self.voiceBroadcastAggregator.delegate = self
    }
    
    private func release() {
        MXLog.debug("[VoiceBroadcastPlaybackViewModel] release")
        if let audioPlayer = audioPlayer {
            audioPlayer.deregisterDelegate(self)
            self.audioPlayer = nil
        }
    }
    
    // MARK: - Public
    
    override func process(viewAction: VoiceBroadcastPlaybackViewAction) {
        switch viewAction {
        case .play:
            play()
        case .playLive:
            playLive()
        case .pause:
            pause()
        case .sliderChange(let didChange):
            didSliderChanged(didChange)
        }
    }
    
    
    // MARK: - Private
    
    /// Listen voice broadcast
    private func play() {
        isLivePlayback = false
        displayLink.isPaused = false
        isActuallyPaused = false
        
        if voiceBroadcastAggregator.isStarted == false {
            // Start the streaming by fetching broadcast chunks
            // The audio player will automatically start the playback on incoming chunks
            MXLog.debug("[VoiceBroadcastPlaybackViewModel] play: Start streaming")
            state.playbackState = .buffering
            voiceBroadcastAggregator.start()
            
            updateDuration()
        } else if let audioPlayer = audioPlayer {
            MXLog.debug("[VoiceBroadcastPlaybackViewModel] play: resume")
            audioPlayer.play()
        } else {
            let chunks = voiceBroadcastAggregator.voiceBroadcast.chunks
            MXLog.debug("[VoiceBroadcastPlaybackViewModel] play: restart from the beginning: \(chunks.count) chunks")
            
            // Reinject all the chunks we already have and play them
            voiceBroadcastChunkQueue.append(contentsOf: chunks)
            processPendingVoiceBroadcastChunks()
        }
    }
    
    private func playLive() {
        guard isLivePlayback == false else {
            MXLog.debug("[VoiceBroadcastPlaybackViewModel] playLive: Already playing live")
            return
        }
        
        isLivePlayback = true
        displayLink.isPaused = false
        isActuallyPaused = false
        
        // Flush the current audio player playlist
        audioPlayer?.removeAllPlayerItems()
        
        if voiceBroadcastAggregator.isStarted == false {
            // Start the streaming by fetching broadcast chunks
            // The audio player will automatically start the playback on incoming chunks
            MXLog.debug("[VoiceBroadcastPlaybackViewModel] playLive: Start streaming")
            state.playbackState = .buffering
            voiceBroadcastAggregator.start()
            
            state.playingState.duration = Float(voiceBroadcastAggregator.voiceBroadcast.duration)
        } else {
            let chunks = voiceBroadcastAggregator.voiceBroadcast.chunks
            MXLog.debug("[VoiceBroadcastPlaybackViewModel] playLive: restart from the last chunk: \(chunks.count) chunks")
            
            // Reinject all the chunks we already have and play the last one
            voiceBroadcastChunkQueue.append(contentsOf: chunks)
            processPendingVoiceBroadcastChunksForLivePlayback()
        }
    }
    
    /// Pause voice broadcast
    private func pause() {
        MXLog.debug("[VoiceBroadcastPlaybackViewModel] pause")
        
        isLivePlayback = false
        displayLink.isPaused = true
        isActuallyPaused = true
        
        if let audioPlayer = audioPlayer, audioPlayer.isPlaying {
            audioPlayer.pause()
        }
    }
    
    private func stopIfVoiceBroadcastOver() {
        MXLog.debug("[VoiceBroadcastPlaybackViewModel] stopIfVoiceBroadcastOver")
        
        // Check if the broadcast is over before stopping everything
        // If not, the player should not stopped. The view state must be move to buffering
        // TODO: Define with more accuracy the threshold to detect the end of the playback
        let remainingTime = state.playingState.duration - state.bindings.progress
        if remainingTime < 500 {
            stop()
        } else {
            state.playbackState = .buffering
        }
    }
    
    private func stop() {
        MXLog.debug("[VoiceBroadcastPlaybackViewModel] stop")
        
        isLivePlayback = false
        displayLink.isPaused = true
        
        // Objects will be released on audioPlayerDidStopPlaying
        audioPlayer?.stop()
    }
    
    
    // MARK: - Voice broadcast chunks playback
    
    /// Start the playback from the beginning or push more chunks to it
    private func processPendingVoiceBroadcastChunks(_ time: TimeInterval? = nil) {
        reorderPendingVoiceBroadcastChunks()
        processNextVoiceBroadcastChunk(time)
    }
    
    /// Start the playback from the last known chunk
    private func processPendingVoiceBroadcastChunksForLivePlayback() {
        let chunks = reorderVoiceBroadcastChunks(chunks: Array(voiceBroadcastAggregator.voiceBroadcast.chunks))
        if let lastChunk = chunks.last {
            MXLog.debug("[VoiceBroadcastPlaybackViewModel] processPendingVoiceBroadcastChunksForLivePlayback. Use the last chunk: sequence: \(lastChunk.sequence) out of the \(voiceBroadcastChunkQueue.count) chunks")
            voiceBroadcastChunkQueue = [lastChunk]
        }
        processNextVoiceBroadcastChunk()
    }
    
    private func reorderPendingVoiceBroadcastChunks() {
        // Make sure we download and process chunks in the right order
        voiceBroadcastChunkQueue = reorderVoiceBroadcastChunks(chunks: voiceBroadcastChunkQueue)
    }
    private func reorderVoiceBroadcastChunks(chunks: [VoiceBroadcastChunk]) -> [VoiceBroadcastChunk] {
        chunks.sorted(by: {$0.sequence < $1.sequence})
    }
    
    private func processNextVoiceBroadcastChunk(_ time: TimeInterval? = nil) {
        MXLog.debug("[VoiceBroadcastPlaybackViewModel] processNextVoiceBroadcastChunk: \(voiceBroadcastChunkQueue.count) chunks remaining")
        
        guard voiceBroadcastChunkQueue.count > 0 else {
            // We cached all chunks. Nothing more to do
            return
        }
        
        if (isActuallyPaused == false && state.playbackState == .paused) || state.playbackState == .stopped {
            state.playbackState = .buffering
        }
        
        // TODO: Control the download rate to avoid to download all chunk in mass
        // We could synchronise it with the number of chunks in the player playlist (audioPlayer.playerItems)
        
        let chunk = voiceBroadcastChunkQueue.removeFirst()
        
        // numberOfSamples is for the equalizer view we do not support yet
        cacheManager.loadAttachment(chunk.attachment, numberOfSamples: 1) { [weak self] result in
            guard let self = self else {
                return
            }
            
            // TODO: Make sure there has no new incoming chunk that should be before this attachment
            // Be careful that this new chunk is not older than the chunk being played by the audio player. Else
            // we will get an unexecpted rewind.
            
            switch result {
            case .success(let result):
                guard result.eventIdentifier == chunk.attachment.eventId else {
                    return
                }
                
                self.voiceBroadcastAttachmentCacheManagerLoadResults.append(result)
                
                if let audioPlayer = self.audioPlayer {
                    // Append the chunk to the current playlist
                    audioPlayer.addContentFromURL(result.url)
                    
                    // Resume the player. Needed after a buffering
                    if audioPlayer.isPlaying == false && self.state.playbackState == .buffering {
                        MXLog.debug("[VoiceBroadcastPlaybackViewModel] processNextVoiceBroadcastChunk: Resume the player")
                        self.displayLink.isPaused = false
                        audioPlayer.play()
                        if let time = time {
                            audioPlayer.seekToTime(time)
                        }
                    }
                } else {
                    // Init and start the player on the first chunk
                    let audioPlayer = self.mediaServiceProvider.audioPlayerForIdentifier(result.eventIdentifier)
                    audioPlayer.registerDelegate(self)
                    
                    audioPlayer.loadContentFromURL(result.url, displayName: chunk.attachment.originalFileName)
                    self.displayLink.isPaused = false
                    audioPlayer.play()
                    if let time = time {
                        audioPlayer.seekToTime(time)
                    }
                    self.audioPlayer = audioPlayer
                }
                
            case .failure (let error):
                MXLog.error("[VoiceBroadcastPlaybackViewModel] processVoiceBroadcastChunkQueue: loadAttachment error", context: error)
                if self.voiceBroadcastChunkQueue.count == 0 {
                    // No more chunk to try. Go to error
                    self.state.playbackState = .error
                }
            }
            
            self.processNextVoiceBroadcastChunk()
        }
    }
    
    private func updateDuration() {
        let duration = voiceBroadcastAggregator.voiceBroadcast.duration
        let time = TimeInterval(duration / 1000)
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        
        state.playingState.duration = Float(duration)
        state.playingState.durationLabel = formatter.string(from: time)
    }
    
    private func didSliderChanged(_ didChange: Bool) {
        acceptProgressUpdates = !didChange
        if didChange {
            audioPlayer?.pause()
            displayLink.isPaused = true
        } else {
            // Flush the current audio player playlist
            audioPlayer?.removeAllPlayerItems()
                        
            let chunks = reorderVoiceBroadcastChunks(chunks: Array(voiceBroadcastAggregator.voiceBroadcast.chunks))
            
            // Reinject the chunks we need and play them
            let remainingTime = state.playingState.duration - state.bindings.progress
            var chunksDuration: UInt = 0
            for chunk in chunks.reversed() {
                chunksDuration += chunk.duration
                voiceBroadcastChunkQueue.append(chunk)
                if Float(chunksDuration) >= remainingTime {
                    break
                }
            }
            
            MXLog.debug("[VoiceBroadcastPlaybackViewModel] didSliderChanged: restart to time: \(state.bindings.progress) milliseconds")
            let time = state.bindings.progress - state.playingState.duration + Float(chunksDuration)
            processPendingVoiceBroadcastChunks(TimeInterval(time / 1000))
        }
    }
    
    @objc private func handleDisplayLinkTick() {
        updateUI()
    }
    
    private func updateUI() {
        guard let playingEventId = voiceBroadcastAttachmentCacheManagerLoadResults.first(where: { result in
                  result.url == audioPlayer?.currentUrl
              })?.eventIdentifier,
              let playingSequence = voiceBroadcastAggregator.voiceBroadcast.chunks.first(where: { chunk in
                  chunk.attachment.eventId == playingEventId
              })?.sequence else {
            return
        }
        
        let progress = Double(voiceBroadcastAggregator.voiceBroadcast.chunks.filter { chunk in
            chunk.sequence < playingSequence
        }.reduce(0) { $0 + $1.duration}) + (audioPlayer?.currentTime.rounded() ?? 0) * 1000
        
        state.bindings.progress = Float(progress)
    }
    
    private static func getBroadcastState(from state: VoiceBroadcastInfo.State) -> VoiceBroadcastState {
        var broadcastState: VoiceBroadcastState
        switch state {
        case .started:
            broadcastState = VoiceBroadcastState.live
        case .paused:
            broadcastState = VoiceBroadcastState.paused
        case .resumed:
            broadcastState = VoiceBroadcastState.live
        case .stopped:
            broadcastState = VoiceBroadcastState.stopped
        }
        
        return broadcastState
    }
}

// MARK: VoiceBroadcastAggregatorDelegate
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
    
    func voiceBroadcastAggregator(_ aggregator: VoiceBroadcastAggregator, didReceiveState: VoiceBroadcastInfo.State) {
        state.broadcastState = VoiceBroadcastPlaybackViewModel.getBroadcastState(from: didReceiveState)
    }
    
    func voiceBroadcastAggregatorDidUpdateData(_ aggregator: VoiceBroadcastAggregator) {
        if isLivePlayback && state.playbackState == .buffering {
            // We started directly with a live playback but there was no known chunks at that time
            // These are the first chunks we get. Start the playback on the latest one
            processPendingVoiceBroadcastChunksForLivePlayback()
        } else {
            processPendingVoiceBroadcastChunks()
        }
    }
}


// MARK: - VoiceMessageAudioPlayerDelegate
extension VoiceBroadcastPlaybackViewModel: VoiceMessageAudioPlayerDelegate {
    func audioPlayerDidFinishLoading(_ audioPlayer: VoiceMessageAudioPlayer) {
    }
    
    func audioPlayerDidStartPlaying(_ audioPlayer: VoiceMessageAudioPlayer) {
        if isLivePlayback {
            state.playbackState = .playingLive
        } else {
            state.playbackState = .playing
        }
    }
    
    func audioPlayerDidPausePlaying(_ audioPlayer: VoiceMessageAudioPlayer) {
        state.playbackState = .paused
    }
    
    func audioPlayerDidStopPlaying(_ audioPlayer: VoiceMessageAudioPlayer) {
        MXLog.debug("[VoiceBroadcastPlaybackViewModel] audioPlayerDidStopPlaying")
        state.playbackState = .stopped
        release()
    }
    
    func audioPlayer(_ audioPlayer: VoiceMessageAudioPlayer, didFailWithError error: Error) {
        state.playbackState = .error
    }
    
    func audioPlayerDidFinishPlaying(_ audioPlayer: VoiceMessageAudioPlayer) {
        MXLog.debug("[VoiceBroadcastPlaybackViewModel] audioPlayerDidFinishPlaying: \(audioPlayer.playerItems.count)")
        stopIfVoiceBroadcastOver()
    }
}
