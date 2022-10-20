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
import Foundation

protocol VoiceBroadcastRecorderServiceDelegate: AnyObject {
    func voiceBroadcastRecorderService(_ service: VoiceBroadcastRecorderServiceProtocol, didUpdateState state: VoiceBroadcastRecorderState)
}

class VoiceBroadcastRecorderService: VoiceBroadcastRecorderServiceProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let roomId: String
    private let session: MXSession
    private var voiceBroadcastService: VoiceBroadcastService? {
        session.voiceBroadcastService
    }
    
    private let audioEngine = AVAudioEngine()
    private let audioNodeBus = AVAudioNodeBus(0)
    
    private var chunkFile: AVAudioFile! = nil
    private var chunkFrames: AVAudioFrameCount = 0
    private var chunkFileNumber: Int = 0
        
    // MARK: Public
    
    weak var serviceDelegate: VoiceBroadcastRecorderServiceDelegate?

    // MARK: - Setup
    
    init(session: MXSession, roomId: String) {
        self.session = session
        self.roomId = roomId
    }
    
    // MARK: - VoiceBroadcastRecorderServiceProtocol
    
    func startRecordingVoiceBroadcast() {
        let inputNode = audioEngine.inputNode

        let inputFormat = inputNode.inputFormat(forBus: audioNodeBus)
        MXLog.debug("[VoiceBroadcastRecorderService] Start recording voice broadcast for bus name : \(String(describing: inputNode.name(forInputBus: audioNodeBus)))")

        inputNode.installTap(onBus: audioNodeBus,
                             bufferSize: 512,
                             format: inputFormat) { (buffer, time) -> Void in
            DispatchQueue.main.async {
                self.writeBuffer(buffer)
            }
        }

        // FIXME: Update state
        try? audioEngine.start()
    }
    
    func stopRecordingVoiceBroadcast() {
        MXLog.debug("[VoiceBroadcastRecorderService] Stop recording voice broadcast")
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: audioNodeBus)

        resetValues()

        voiceBroadcastService?.stopVoiceBroadcast(success: { [weak self] _ in
            MXLog.debug("[VoiceBroadcastRecorderService] Stopped")
            
            guard let self = self else { return }
            
            // Update state
            self.serviceDelegate?.voiceBroadcastRecorderService(self, didUpdateState: .stopped)
            
            // Send current chunk
            self.sendChunkFile(at: self.chunkFile.url)
            
            self.session.tearDownVoiceBroadcastService()
        }, failure: { error in
            MXLog.error("[VoiceBroadcastRecorderService] Failed to stop voice broadcast", context: error)
        })
    }
    
    func pauseRecordingVoiceBroadcast() {
        audioEngine.pause()
        
        voiceBroadcastService?.pauseVoiceBroadcast(success: { [weak self] _ in
            guard let self = self else { return }
            
            // Send current chunk
            self.sendChunkFile(at: self.chunkFile.url)
            self.chunkFile = nil
            
        }, failure: { error in
            MXLog.error("[VoiceBroadcastRecorderService] Failed to pause voice broadcast", context: error)
        })
    }
    
    func resumeRecordingVoiceBroadcast() {
        try? audioEngine.start()
        
        voiceBroadcastService?.resumeVoiceBroadcast(success: { _ in
            //
        }, failure: { error in
            MXLog.error("[VoiceBroadcastRecorderService] Failed to resume voice broadcast", context: error)
        })
    }
    
    // MARK: - Private
    /// Reset chunk values.
    private func resetValues() {
        chunkFrames = 0
        chunkFileNumber = 0
    }
    
    /// Write audio buffer to chunk file.
    private func writeBuffer(_ buffer: AVAudioPCMBuffer) {
        let sampleRate = buffer.format.sampleRate
        
        if chunkFile == nil {
            createNewChunkFile(sampleRate: sampleRate)
        }
        try? chunkFile.write(from: buffer)
        
        chunkFrames += buffer.frameLength
        
        if chunkFrames > AVAudioFrameCount(Double(BuildSettings.voiceBroadcastChunkLength) * sampleRate) {
            sendChunkFile(at: chunkFile.url)
            // Reset chunkFile
            chunkFile = nil
        }
    }
    
    /// Create new chunk file with sample rate.
    private func createNewChunkFile(sampleRate: Float64) {
        guard let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            // FIXME: Manage error
            return
        }
        let temporaryFileName = "VoiceBroadcastChunk-\(roomId)-\(chunkFileNumber)"
        let fileUrl = directory
            .appendingPathComponent(temporaryFileName)
            .appendingPathExtension("m4a")
        MXLog.debug("[VoiceBroadcastRecorderService] Create chunk file to \(fileUrl)")
        
        let settings: [String: Any] = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                                     AVSampleRateKey: sampleRate,
                                     AVEncoderBitRateKey: 128000,
                                     AVNumberOfChannelsKey: 1,
                                     AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
        
        chunkFile = try? AVAudioFile(forWriting: fileUrl, settings: settings)
        
        if chunkFile != nil {
            chunkFileNumber += 1
            chunkFrames = 0
        } else {
            stopRecordingVoiceBroadcast()
            // FIXME: Manage error and stop recording ?
        }
    }
    
    /// Send chunk file to the server.
    private func sendChunkFile(at url: URL) {
        guard let voiceBroadcastService = voiceBroadcastService else {
            // FIXME: Manage error
            return
        }
        
        let dispatchGroup = DispatchGroup()
        var duration = 0.0
        
        dispatchGroup.enter()
        VoiceMessageAudioConverter.mediaDurationAt(url) { result in
            switch result {
            case .success:
                if let someDuration = try? result.get() {
                    duration = someDuration
                } else {
                    MXLog.error("[VoiceBroadcastRecorderService] Failed to retrieve media duration")
                }
            case .failure(let error):
                MXLog.error("[VoiceBroadcastRecorderService] Failed to get audio duration", context: error)
            }
            
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            voiceBroadcastService.sendChunkOfVoiceBroadcast(audioFileLocalURL: url,
                                                            mimeType: "audio/mp4",
                                                            duration: UInt(duration * 1000),
                                                            samples: nil,
                                                            sequence: UInt(self.chunkFileNumber)) { eventId in
                MXLog.debug("[VoiceBroadcastRecorderService] Send voice broadcast chunk with success.")
                if eventId != nil {
                    self.deleteRecording(at: url)
                }
            } failure: { error in
                MXLog.error("[VoiceBroadcastRecorderService] Failed to send voice broadcast chunk.", context: error)
            }
        }
    }
    
    /// Delete voice broadcast chunk at URL.
    private func deleteRecording(at url: URL?) {
        guard let url = url else {
            return
        }
        
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            MXLog.error("[VoiceBroadcastRecorderService] Delete chunk file error.", context: error)
        }
    }
}
