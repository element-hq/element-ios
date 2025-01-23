// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

protocol VoiceMessageAudioPlayerDelegate: AnyObject {
    func audioPlayerDidStartLoading(_ audioPlayer: VoiceMessageAudioPlayer)
    func audioPlayerDidFinishLoading(_ audioPlayer: VoiceMessageAudioPlayer)
    
    func audioPlayerDidStartPlaying(_ audioPlayer: VoiceMessageAudioPlayer)
    func audioPlayerDidPausePlaying(_ audioPlayer: VoiceMessageAudioPlayer)
    func audioPlayerDidStopPlaying(_ audioPlayer: VoiceMessageAudioPlayer)
    func audioPlayerDidFinishPlaying(_ audioPlayer: VoiceMessageAudioPlayer)
    
    func audioPlayer(_ audioPlayer: VoiceMessageAudioPlayer, didFailWithError: Error)
}

enum VoiceMessageAudioPlayerError: Error {
    case genericError
}

class VoiceMessageAudioPlayer: NSObject {
    
    private var playerItem: AVPlayerItem?
    private var audioPlayer: AVQueuePlayer?
    
    private var statusObserver: NSKeyValueObservation?
    private var playbackBufferEmptyObserver: NSKeyValueObservation?
    private var rateObserver: NSKeyValueObservation?
    private var playToEndObserver: NSObjectProtocol?
    private var appBackgroundObserver: NSObjectProtocol?
    
    private let delegateContainer = DelegateContainer()
    
    private(set) var url: URL?
    private(set) var displayName: String?
    
    var isPlaying: Bool {
        guard let audioPlayer = audioPlayer else {
            return false
        }
        
        return audioPlayer.currentItem != nil && (audioPlayer.rate > 0)
    }
    
    var duration: TimeInterval {
        return abs(CMTimeGetSeconds(self.audioPlayer?.currentItem?.duration ?? .zero))
    }
    
    var currentTime: TimeInterval {
        let currentTime = abs(CMTimeGetSeconds(audioPlayer?.currentTime() ?? .zero))
        return currentTime.isFinite ? currentTime : .zero
    }
    
    var playerItems: [AVPlayerItem] {
        guard let audioPlayer = audioPlayer else {
            return []
        }
        
        return audioPlayer.items()
    }
    
    var currentUrl: URL? {
        return (audioPlayer?.currentItem?.asset as? AVURLAsset)?.url
    }
    
    private(set) var isStopped = true
    
    deinit {
        removeObservers()
    }
    
    func loadContentFromURL(_ url: URL, displayName: String? = nil) {
        if self.url == url {
            return
        }
        
        self.url = url
        self.displayName = displayName
        
        removeObservers()
        
        delegateContainer.notifyDelegatesWithBlock { delegate in
            (delegate as? VoiceMessageAudioPlayerDelegate)?.audioPlayerDidStartLoading(self)
        }
        
        playerItem = AVPlayerItem(url: url)
        audioPlayer = AVQueuePlayer(playerItem: playerItem)
        
        addObservers()
    }
    
    func addContentFromURL(_ url: URL) {
        let playerItem = AVPlayerItem(url: url)
        audioPlayer?.insert(playerItem, after: nil)
        
        // audioPlayerDidFinishPlaying must be called on this last AVPlayerItem
        NotificationCenter.default.removeObserver(playToEndObserver as Any)
        playToEndObserver = NotificationCenter.default.addObserver(forName: Notification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem, queue: nil) { [weak self] notification in
            guard let self = self else { return }
            
            self.delegateContainer.notifyDelegatesWithBlock { delegate in
                (delegate as? VoiceMessageAudioPlayerDelegate)?.audioPlayerDidFinishPlaying(self)
            }
        }
    }
    
    func reloadContentIfNeeded() {
        if let url, let audioPlayer, audioPlayer.currentItem == nil {
            self.url = nil
            loadContentFromURL(url)
        }
    }
    
    func removeAllPlayerItems() {
        audioPlayer?.removeAllItems()
    }
    
    func unloadContent() {
        url = nil
        audioPlayer?.replaceCurrentItem(with: nil)
    }
    
    func play() {
        isStopped = false
        
        reloadContentIfNeeded()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            MXLog.error("Could not redirect audio playback to speakers.")
        }
        
        audioPlayer?.play()
    }
    
    func pause() {
        audioPlayer?.pause()
    }
    
    func stop() {
        if isStopped {
            return
        }
        
        isStopped = true
        audioPlayer?.pause()
        audioPlayer?.seek(to: .zero)
    }
    
    func seekToTime(_ time: TimeInterval, completionHandler: @escaping (Bool) -> Void = { _ in }) {
        audioPlayer?.seek(to: CMTime(seconds: time, preferredTimescale: 60000), completionHandler: completionHandler)
    }
    
    func registerDelegate(_ delegate: VoiceMessageAudioPlayerDelegate) {
        delegateContainer.registerDelegate(delegate)
    }
    
    func deregisterDelegate(_ delegate: VoiceMessageAudioPlayerDelegate) {
        delegateContainer.deregisterDelegate(delegate)
    }
    
    // MARK: - Private
    
    private func addObservers() {
        guard let audioPlayer = audioPlayer, let playerItem = playerItem else {
            return
        }
        
        statusObserver = playerItem.observe(\.status, options: [.old, .new]) { [weak self] item, change in
            guard let self = self else { return }
            
            switch playerItem.status {
            case .failed:
                self.delegateContainer.notifyDelegatesWithBlock { delegate in
                    (delegate as? VoiceMessageAudioPlayerDelegate)?.audioPlayer(self, didFailWithError: playerItem.error ?? VoiceMessageAudioPlayerError.genericError)
                }
            case .readyToPlay:
                self.delegateContainer.notifyDelegatesWithBlock { delegate in
                    (delegate as? VoiceMessageAudioPlayerDelegate)?.audioPlayerDidFinishLoading(self)
                }
            default:
                break
            }
        }
        
        playbackBufferEmptyObserver = playerItem.observe(\.isPlaybackBufferEmpty, options: [.old, .new]) { [weak self] item, change in
            guard let self = self else { return }
            
            if playerItem.isPlaybackBufferEmpty {
                self.delegateContainer.notifyDelegatesWithBlock { delegate in
                    (delegate as? VoiceMessageAudioPlayerDelegate)?.audioPlayerDidStartLoading(self)
                }
            } else {
                self.delegateContainer.notifyDelegatesWithBlock { delegate in
                    (delegate as? VoiceMessageAudioPlayerDelegate)?.audioPlayerDidFinishLoading(self)
                }
            }
        }
        
        rateObserver = audioPlayer.observe(\.rate, options: [.old, .new]) { [weak self] player, change in
            guard let self = self else { return }
            
            if audioPlayer.rate == 0.0 {
                if self.isStopped {
                    self.delegateContainer.notifyDelegatesWithBlock { delegate in
                        (delegate as? VoiceMessageAudioPlayerDelegate)?.audioPlayerDidStopPlaying(self)
                    }
                } else {
                    self.delegateContainer.notifyDelegatesWithBlock { delegate in
                        (delegate as? VoiceMessageAudioPlayerDelegate)?.audioPlayerDidPausePlaying(self)
                    }
                }
            } else {
                self.delegateContainer.notifyDelegatesWithBlock { delegate in
                    (delegate as? VoiceMessageAudioPlayerDelegate)?.audioPlayerDidStartPlaying(self)
                }
            }
        }
        
        playToEndObserver = NotificationCenter.default.addObserver(forName: Notification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem, queue: nil) { [weak self] notification in
            guard let self = self else { return }
            
            self.delegateContainer.notifyDelegatesWithBlock { delegate in
                (delegate as? VoiceMessageAudioPlayerDelegate)?.audioPlayerDidFinishPlaying(self)
            }
        }
        
        appBackgroundObserver = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { [weak self] _ in
            guard let self = self, !BuildSettings.allowBackgroundAudioMessagePlayback else { return }
            
            self.pause()
            self.delegateContainer.notifyDelegatesWithBlock { delegate in
                (delegate as? VoiceMessageAudioPlayerDelegate)?.audioPlayerDidPausePlaying(self)
            }
        }
    }
    
    private func removeObservers() {
        statusObserver?.invalidate()
        playbackBufferEmptyObserver?.invalidate()
        rateObserver?.invalidate()
        NotificationCenter.default.removeObserver(playToEndObserver as Any)
        NotificationCenter.default.removeObserver(appBackgroundObserver as Any)
    }
}

extension VoiceMessageAudioPlayerDelegate {
    func audioPlayerDidStartLoading(_ audioPlayer: VoiceMessageAudioPlayer) { }
    
    func audioPlayerDidFinishLoading(_ audioPlayer: VoiceMessageAudioPlayer) { }
    
    func audioPlayerDidStartPlaying(_ audioPlayer: VoiceMessageAudioPlayer) { }
    
    func audioPlayerDidPausePlaying(_ audioPlayer: VoiceMessageAudioPlayer) { }
    
    func audioPlayerDidStopPlaying(_ audioPlayer: VoiceMessageAudioPlayer) { }
    
    func audioPlayerDidFinishPlaying(_ audioPlayer: VoiceMessageAudioPlayer) { }
    
    func audioPlayer(_ audioPlayer: VoiceMessageAudioPlayer, didFailWithError: Error) { }
}
