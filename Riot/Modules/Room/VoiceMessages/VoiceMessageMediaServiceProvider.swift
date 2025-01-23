// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MediaPlayer

@objc public class VoiceMessageMediaServiceProvider: NSObject, VoiceMessageAudioPlayerDelegate, VoiceMessageAudioRecorderDelegate {
    
    private enum Constants {
        static let roomAvatarImageSize: CGSize = CGSize(width: 600, height: 600)
        static let roomAvatarFontSize: CGFloat = 40.0
        static let roomAvatarMimetype: String = "image/jpeg"
    }
    
    private var roomAvatarLoader: MXMediaLoader?
    private let audioPlayers: NSMapTable<NSString, VoiceMessageAudioPlayer>
    private let audioRecorders: NSHashTable<VoiceMessageAudioRecorder>
    private let nowPlayingInfoDelegates: NSMapTable<VoiceMessageAudioPlayer, VoiceMessageNowPlayingInfoDelegate>
    
    private var displayLink: CADisplayLink!
    
    
    
    // Retain active audio players(playing or paused) so it doesn't stop playing on timeline cell reuse
    // and we can pause/resume players on switching rooms.
    private var activeAudioPlayers: Set<VoiceMessageAudioPlayer>
    
    // Keep reference to currently playing player for remote control.
    private var currentlyPlayingAudioPlayer: VoiceMessageAudioPlayer?
    
    @objc public static let sharedProvider = VoiceMessageMediaServiceProvider()
    
    private var roomAvatar: UIImage?
    @objc public var currentRoomSummary: MXRoomSummary? {
        didSet {
            //  set avatar placeholder for now
            roomAvatar = AvatarGenerator.generateAvatar(forMatrixItem: currentRoomSummary?.roomId,
                                                        withDisplayName: currentRoomSummary?.displayName,
                                                        size: Constants.roomAvatarImageSize.width,
                                                        andFontSize: Constants.roomAvatarFontSize)
            
            guard let avatarUrl = currentRoomSummary?.avatar else {
                return
            }
            
            if let cachePath = MXMediaManager.thumbnailCachePath(forMatrixContentURI: avatarUrl,
                                                                 andType: Constants.roomAvatarMimetype,
                                                                 inFolder: currentRoomSummary?.roomId,
                                                                 toFitViewSize: Constants.roomAvatarImageSize,
                                                                 with: MXThumbnailingMethodCrop),
               FileManager.default.fileExists(atPath: cachePath) {
                //  found in the cache, load it
                roomAvatar = MXMediaManager.loadThroughCache(withFilePath: cachePath)
            } else {
                //  cancel previous loader first
                roomAvatarLoader?.cancel()
                roomAvatarLoader = nil
                
                guard let mediaManager = currentRoomSummary?.mxSession.mediaManager else {
                    return
                }
                
                //  not found in the cache, download it
                roomAvatarLoader = mediaManager.downloadThumbnail(fromMatrixContentURI: avatarUrl,
                                                                  withType: Constants.roomAvatarMimetype,
                                                                  inFolder: currentRoomSummary?.roomId,
                                                                  toFitViewSize: Constants.roomAvatarImageSize,
                                                                  with: MXThumbnailingMethodCrop,
                                                                  success: { filePath in
                                                                    if let filePath = filePath {
                                                                        self.roomAvatar = MXMediaManager.loadThroughCache(withFilePath: filePath)
                                                                    }
                                                                    self.roomAvatarLoader = nil
                                                                  }, failure: { error in
                                                                    self.roomAvatarLoader = nil
                                                                  })
            }
        }
    }
    
    private override init() {
        audioPlayers = NSMapTable<NSString, VoiceMessageAudioPlayer>(valueOptions: .weakMemory)
        audioRecorders = NSHashTable<VoiceMessageAudioRecorder>(options: .weakMemory)
        nowPlayingInfoDelegates = NSMapTable<VoiceMessageAudioPlayer, VoiceMessageNowPlayingInfoDelegate>(keyOptions: .weakMemory, valueOptions: .weakMemory)
        activeAudioPlayers = Set<VoiceMessageAudioPlayer>()
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
    
    @objc func pauseAllServices() {
        pauseAllServicesExcept(nil)
    }
    
    func registerNowPlayingInfoDelegate(_ delegate: VoiceMessageNowPlayingInfoDelegate, forPlayer player: VoiceMessageAudioPlayer) {
        nowPlayingInfoDelegates.setObject(delegate, forKey: player)
    }
    
    func deregisterNowPlayingInfoDelegate(forPlayer player: VoiceMessageAudioPlayer) {
        nowPlayingInfoDelegates.removeObject(forKey: player)
    }
    
    // MARK: - VoiceMessageAudioPlayerDelegate
    
    func audioPlayerDidStartPlaying(_ audioPlayer: VoiceMessageAudioPlayer) {
        currentlyPlayingAudioPlayer = audioPlayer
        activeAudioPlayers.insert(audioPlayer)
        
        let shouldSetupRemoteCommandCenter = nowPlayingInfoDelegates.object(forKey: audioPlayer)?.shouldSetupRemoteCommandCenter(audioPlayer: audioPlayer) ?? true
        if shouldSetupRemoteCommandCenter {
            setUpRemoteCommandCenter()
        } else {
            // clean up the remote command center
            tearDownRemoteCommandCenter()
        }
        pauseAllServicesExcept(audioPlayer)
    }
    
    func audioPlayerDidStopPlaying(_ audioPlayer: VoiceMessageAudioPlayer) {
        if currentlyPlayingAudioPlayer == audioPlayer {
            // If we have a NowPlayingInfoDelegate for this player
            let nowPlayingInfoDelegate = nowPlayingInfoDelegates.object(forKey: audioPlayer)

            // ask the delegate if we should disconnect from NowPlayingInfoCenter (if there's no delegate, we consider it safe to disconnect it)
            if nowPlayingInfoDelegate?.shouldDisconnectFromNowPlayingInfoCenter(audioPlayer: audioPlayer) ?? true {
                currentlyPlayingAudioPlayer = nil
                tearDownRemoteCommandCenter()
            }
        }
        activeAudioPlayers.remove(audioPlayer)
    }
    
    func audioPlayerDidFinishPlaying(_ audioPlayer: VoiceMessageAudioPlayer) {
        if currentlyPlayingAudioPlayer == audioPlayer {
            // If we have a NowPlayingInfoDelegate for this player
            let nowPlayingInfoDelegate = nowPlayingInfoDelegates.object(forKey: audioPlayer)

            // ask the delegate if we should disconnect from NowPlayingInfoCenter (if there's no delegate, we consider it safe to disconnect it)
            if nowPlayingInfoDelegate?.shouldDisconnectFromNowPlayingInfoCenter(audioPlayer: audioPlayer) ?? true {
                currentlyPlayingAudioPlayer = nil
                tearDownRemoteCommandCenter()
            }
        }
        activeAudioPlayers.remove(audioPlayer)
    }
    
    // MARK: - VoiceMessageAudioRecorderDelegate
    
    func audioRecorderDidStartRecording(_ audioRecorder: VoiceMessageAudioRecorder) {
        pauseAllServicesExcept(audioRecorder)
    }
    
    // MARK: - Private
    
    private func pauseAllServicesExcept(_ service: AnyObject?) {
        for audioRecorder in audioRecorders.allObjects {
            if audioRecorder === service {
                continue
            }
            
            // We should release the audio session only if we want to pause all services
            let shouldReleaseAudioSession = (service == nil)
            audioRecorder.stopRecording(releaseAudioSession: shouldReleaseAudioSession)
        }
        
        guard let audioPlayersEnumerator = audioPlayers.objectEnumerator() else {
            return
        }
        
        for case let audioPlayer as VoiceMessageAudioPlayer in audioPlayersEnumerator {
            if audioPlayer === service {
                continue
            }
            
            audioPlayer.pause()
        }
    }
    
    @objc private func handleDisplayLinkTick() {
        updateNowPlayingInfoCenter()
    }
    
    private func setUpRemoteCommandCenter() {
        guard BuildSettings.allowBackgroundAudioMessagePlayback else {
            return
        }
        
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
        nowPlayingInfoCenter.playbackState = .stopped
        
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = false
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.isEnabled = false
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.skipForwardCommand.isEnabled = false
        commandCenter.skipForwardCommand.removeTarget(nil)
        commandCenter.skipBackwardCommand.isEnabled = false
        commandCenter.skipBackwardCommand.removeTarget(nil)
    }
    
    private func updateNowPlayingInfoCenter() {
        guard let audioPlayer = currentlyPlayingAudioPlayer else {
            return
        }
        
        // Checks if we have a delegate for this player, or if we should update the NowPlayingInfoCenter ourselves
        if let nowPlayingInfoDelegate = nowPlayingInfoDelegates.object(forKey: audioPlayer) {
            nowPlayingInfoDelegate.updateNowPlayingInfoCenter(forPlayer: audioPlayer)
        } else {
            let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
            nowPlayingInfoCenter.nowPlayingInfo = [MPMediaItemPropertyTitle: VectorL10n.voiceMessageLockScreenPlaceholder,
                                        MPMediaItemPropertyPlaybackDuration: audioPlayer.duration as Any,
                                MPNowPlayingInfoPropertyElapsedPlaybackTime: audioPlayer.currentTime as Any]
        }
    }
}
