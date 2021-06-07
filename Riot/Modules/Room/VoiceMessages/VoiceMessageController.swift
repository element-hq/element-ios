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

@objc public protocol VoiceMessageControllerDelegate: AnyObject {
    func voiceMessageController(_ voiceMessageController: VoiceMessageController, didRequestSendForFileAtURL url: URL, completion: @escaping (Bool) -> Void)
}

public class VoiceMessageController: NSObject, VoiceMessageToolbarViewDelegate, AudioRecorderDelegate {
    
    private let themeService: ThemeService
    private let _voiceMessageToolbarView: VoiceMessageToolbarView
    
    private var audioRecorder: AudioRecorder?
    
    @objc public weak var delegate: VoiceMessageControllerDelegate?
    
    @objc public var voiceMessageToolbarView: UIView {
        return _voiceMessageToolbarView
    }
    
    @objc public init(themeService: ThemeService) {
        _voiceMessageToolbarView = VoiceMessageToolbarView.instanceFromNib()
        self.themeService = themeService
        
        super.init()
        
        _voiceMessageToolbarView.delegate = self
        
        self._voiceMessageToolbarView.update(theme: self.themeService.theme)
        NotificationCenter.default.addObserver(self, selector: #selector(handleThemeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    // MARK: - VoiceMessageToolbarViewDelegate
    
    func voiceMessageToolbarViewDidRequestRecordingStart(_ toolbarView: VoiceMessageToolbarView) {
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(ProcessInfo().globallyUniqueString)
        
        audioRecorder = AudioRecorder()
        audioRecorder?.delegate = self
        audioRecorder?.recordWithOuputURL(temporaryFileURL)
    }
    
    func voiceMessageToolbarViewDidRequestRecordingFinish(_ toolbarView: VoiceMessageToolbarView) {
        audioRecorder?.stopRecording()
        
        guard let url = audioRecorder?.url else {
            MXLog.error("Invalid audio recording URL")
            return
        }
        
        delegate?.voiceMessageController(self, didRequestSendForFileAtURL: url) { [weak self] success in
            self?.deleteRecordingAtURL(url)
        }
    }
    
    func voiceMessageToolbarViewDidRequestRecordingCancel(_ toolbarView: VoiceMessageToolbarView) {
        audioRecorder?.stopRecording()
        deleteRecordingAtURL(audioRecorder?.url)
    }
    
    // MARK: - AudioRecorderDelegate
    
    func audioRecorderDidStartRecording(_ audioRecorder: AudioRecorder) {
        _voiceMessageToolbarView.state = .recording
    }
    
    func audioRecorderDidFinishRecording(_ audioRecorder: AudioRecorder) {
        _voiceMessageToolbarView.state = .idle
    }
    
    func audioRecorder(_ audioRecorder: AudioRecorder, didFailWithError: Error) {
        MXLog.error("Failed recording voice message.")
        _voiceMessageToolbarView.state = .idle
    }
    
    // MARK: - Private
    
    private func deleteRecordingAtURL(_ url: URL?) {
        guard let url = url else {
            return
        }
        
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            MXLog.error(error)
        }
    }
    
    @objc private func handleThemeDidChange() {
        self._voiceMessageToolbarView.update(theme: self.themeService.theme)
    }
}
