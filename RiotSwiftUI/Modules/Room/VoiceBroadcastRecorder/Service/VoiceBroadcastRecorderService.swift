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

class VoiceBroadcastRecorderService: VoiceBroadcastRecorderServiceProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let roomId: String
    private let session: MXSession
    private var voiceBroadcastService: VoiceBroadcastService? {
        session.voiceBroadcastService
    }
    
    private let audioEngine = AVAudioEngine()
    
    private var chunkFile: AVAudioFile! = nil
    private var chunkFrames: AVAudioFrameCount = 0
    private var chunkFileNumber: Int = 0
        
    // MARK: Public

    // MARK: - Setup
    
    init(session: MXSession, roomId: String) {
        self.session = session
        self.roomId = roomId
    }
    
    // MARK: - VoiceBroadcastRecorderServiceProtocol
    
    func startRecordingVoiceBroadcast() {
        let inputNode = audioEngine.inputNode
        
        let inputBus = AVAudioNodeBus(0)
        let inputFormat = inputNode.inputFormat(forBus: inputBus)
        MXLog.debug("[VoiceBroadcastRecorderService] Start recording voice broadcast for bus name : \(String(describing: inputNode.name(forInputBus: inputBus)))")
        
        inputNode.installTap(onBus: inputBus,
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
        audioEngine.stop()
        audioEngine.reset() // FIXME: Really needed ?
        resetValues()
        
        voiceBroadcastService?.stopVoiceBroadcast(success: { _ in
            // update recording state
        }, failure: { error in
            MXLog.error("[VoiceBroadcastRecorderService] Failed to stop voice broadcast", context: error)
        })
    }
    
    func pauseRecordingVoiceBroadcast() {
        audioEngine.pause()
        
        voiceBroadcastService?.pauseVoiceBroadcast(success: { _ in
            // update recording state
        }, failure: { error in
            MXLog.error("[VoiceBroadcastRecorderService] Failed to pause voice broadcast", context: error)
        })
    }
    
    func resumeRecordingVoiceBroadcast() {
        try? audioEngine.start() // FIXME: Verifiy if start is ok for a restart/resume
        
        voiceBroadcastService?.resumeVoiceBroadcast(success: { _ in
            // update recording state
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
        let fileUrl = directory.appendingPathComponent("VoiceBroadcastChunk-\(roomId)-\(chunkFileNumber).m4a")
        MXLog.debug("[VoiceBroadcastRecorderService] Create chunk file to \(fileUrl)")
        
        let settings: [String: Any] = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                                     AVSampleRateKey: sampleRate,
                                     AVEncoderBitRateKey: 128000,
                                     AVNumberOfChannelsKey: 1,
                                     AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
        
        chunkFile = try! AVAudioFile(forWriting: fileUrl, settings: settings)
        
        chunkFileNumber += 1
        chunkFrames = 0
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
                    MXLog.error("[VoiceBroadcastRecorderService] Failed retrieving media duration")
                }
            case .failure(let error):
                MXLog.error("[VoiceBroadcastRecorderService] Failed getting audio duration", context: error)
            }
            
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            voiceBroadcastService.sendChunkOfVoiceBroadcast(audioFileLocalURL: url,
                                                            mimeType: "audio/mp4",
                                                            duration: UInt(duration * 1000),
                                                            samples: nil) { eventId in
                MXLog.debug("[VoiceBroadcastRecorderService] sendChunkOfVoiceBroadcast success.")
                if eventId != nil {
                    self.deleteRecording(at: url)
                }
            } failure: { error in
                MXLog.error("[VoiceBroadcastRecorderService] sendChunkOfVoiceBroadcast error.", context: error)
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
            MXLog.error("[VoiceBroadcastRecorderService] deleteRecordingAtURL:", context: error)
        }
    }
}
