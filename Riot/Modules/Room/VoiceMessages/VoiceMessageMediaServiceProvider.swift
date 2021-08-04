// 
// Copyright 2021 New Vector Ltd
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

import Foundation
import MediaPlayer

@objc public class VoiceMessageMediaServiceProvider: NSObject, VoiceMessageAudioPlayerDelegate, VoiceMessageAudioRecorderDelegate {
    
    private enum Constants {
        static let roomAvatarImageSize: CGFloat = 100.0
        static let roomAvatarFontSize: CGFloat = 40.0
    }
    
    private let audioPlayers: NSMapTable<NSString, VoiceMessageAudioPlayer>
    private let audioRecorders: NSHashTable<VoiceMessageAudioRecorder>
    
    private var displayLink: CADisplayLink!
    
    // Retain currently playing audio player so it doesn't stop playing on timeline cell reuse
    private var currentlyPlayingAudioPlayer: VoiceMessageAudioPlayer?
    
    @objc public static let sharedProvider = VoiceMessageMediaServiceProvider()
    
    private var roomAvatar: UIImage?
    @objc public var currentRoomSummary: MXRoomSummary? {
        didSet {
            roomAvatar = AvatarGenerator.generateAvatar(forMatrixItem: currentRoomSummary?.roomId,
                                                        withDisplayName: currentRoomSummary?.displayname,
                                                        size: Constants.roomAvatarImageSize,
                                                        andFontSize: Constants.roomAvatarFontSize)
        }
    }
    
    private override init() {
        audioPlayers = NSMapTable<NSString, VoiceMessageAudioPlayer>(valueOptions: .weakMemory)
        audioRecorders = NSHashTable<VoiceMessageAudioRecorder>(options: .weakMemory)
        
        super.init()
        
        displayLink = CADisplayLink(target: WeakTarget(self, selector: #selector(handleDisplayLinkTick)), selector: WeakTarget.triggerSelector)
        displayLink.isPaused = true
        displayLink.add(to: .current, forMode: .common)
    }
    
    @objc func audioPlayerForIdentifier(_ identifier: String) -> VoiceMessageAudioPlayer {
        if let audioPlayer = audioPlayers.object(forKey: identifier as NSString) {
            return audioPlayer
        }
        
        let audioPlayer = VoiceMessageAudioPlayer()
        audioPlayer.registerDelegate(self)
        audioPlayers.setObject(audioPlayer, forKey: identifier as NSString)
        return audioPlayer
    }
    
    @objc func audioRecorder() -> VoiceMessageAudioRecorder {
        let audioRecorder = VoiceMessageAudioRecorder()
        audioRecorder.registerDelegate(self)
        audioRecorders.add(audioRecorder)
        return audioRecorder
    }
    
    @objc func stopAllServices() {
        stopAllServicesExcept(nil)
    }
    
    // MARK: - VoiceMessageAudioPlayerDelegate
    
    func audioPlayerDidStartPlaying(_ audioPlayer: VoiceMessageAudioPlayer) {
        currentlyPlayingAudioPlayer = audioPlayer
        setUpRemoteCommandCenter()
        stopAllServicesExcept(audioPlayer)
    }
    
    func audioPlayerDidStopPlaying(_ audioPlayer: VoiceMessageAudioPlayer) {
        if currentlyPlayingAudioPlayer == audioPlayer {
            currentlyPlayingAudioPlayer = nil
            tearDownRemoteCommandCenter()
        }
    }
    
    func audioPlayerDidFinishPlaying(_ audioPlayer: VoiceMessageAudioPlayer) {
        if currentlyPlayingAudioPlayer == audioPlayer {
            currentlyPlayingAudioPlayer = nil
            tearDownRemoteCommandCenter()
        }
    }
    
    // MARK: - VoiceMessageAudioRecorderDelegate
    
    func audioRecorderDidStartRecording(_ audioRecorder: VoiceMessageAudioRecorder) {
        stopAllServicesExcept(audioRecorder)
    }
    
    // MARK: - Private
    
    private func stopAllServicesExcept(_ service: AnyObject?) {
        for audioRecorder in audioRecorders.allObjects {
            if audioRecorder === service {
                continue
            }
            
            audioRecorder.stopRecording()
        }
        
        guard let audioPlayersEnumerator = audioPlayers.objectEnumerator() else {
            return
        }
        
        for case let audioPlayer as VoiceMessageAudioPlayer in audioPlayersEnumerator {
            if audioPlayer === service {
                continue
            }
            
            audioPlayer.stop()
            audioPlayer.unloadContent()
        }
    }
    
    @objc private func handleDisplayLinkTick() {
        updateNowPlayingInfoCenter()
    }
    
    private func setUpRemoteCommandCenter() {
        displayLink.isPaused = false
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.playCommand.addTarget { [weak self] event in
            guard let audioPlayer = self?.currentlyPlayingAudioPlayer else {
                return MPRemoteCommandHandlerStatus.commandFailed
            }
            
            audioPlayer.play()
            
            return MPRemoteCommandHandlerStatus.success
        }
        
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.pauseCommand.addTarget { [weak self] event in
            guard let audioPlayer = self?.currentlyPlayingAudioPlayer else {
                return MPRemoteCommandHandlerStatus.commandFailed
            }
            
            audioPlayer.pause()

            return MPRemoteCommandHandlerStatus.success
        }
        
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.removeTarget(nil)
        commandCenter.skipForwardCommand.addTarget { [weak self] event in
            guard let audioPlayer = self?.currentlyPlayingAudioPlayer, let skipEvent = event as? MPSkipIntervalCommandEvent else {
                return MPRemoteCommandHandlerStatus.commandFailed
            }
            
            audioPlayer.seekToTime(audioPlayer.currentTime + skipEvent.interval)
            
            return MPRemoteCommandHandlerStatus.success
        }
        
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.removeTarget(nil)
        commandCenter.skipBackwardCommand.addTarget { [weak self] event in
            guard let audioPlayer = self?.currentlyPlayingAudioPlayer, let skipEvent = event as? MPSkipIntervalCommandEvent else {
                return MPRemoteCommandHandlerStatus.commandFailed
            }
            
            audioPlayer.seekToTime(audioPlayer.currentTime - skipEvent.interval)
            
            return MPRemoteCommandHandlerStatus.success
        }
    }
    
    private func tearDownRemoteCommandCenter() {
        displayLink.isPaused = true
        
        UIApplication.shared.endReceivingRemoteControlEvents()
        
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        nowPlayingInfoCenter.nowPlayingInfo = nil
    }
    
    private func updateNowPlayingInfoCenter() {
        guard let audioPlayer = currentlyPlayingAudioPlayer else {
            return
        }
        
        let artwork = MPMediaItemArtwork(boundsSize: .init(width: Constants.roomAvatarImageSize, height: Constants.roomAvatarImageSize)) { [weak self] size in
            return self?.roomAvatar ?? UIImage()
        }
        
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        nowPlayingInfoCenter.nowPlayingInfo = [MPMediaItemPropertyTitle: audioPlayer.displayName ?? "Voice message",
                                               MPMediaItemPropertyArtist: currentRoomSummary?.displayname as Any,
                                               MPMediaItemPropertyArtwork: artwork,
                                               MPMediaItemPropertyPlaybackDuration: audioPlayer.duration as Any,
                                               MPNowPlayingInfoPropertyElapsedPlaybackTime: audioPlayer.currentTime as Any]
    }
}
