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

typealias VoiceBroadcastRecorderViewModelType = StateStoreViewModel<VoiceBroadcastRecorderViewState, VoiceBroadcastRecorderViewAction>

class VoiceBroadcastRecorderViewModel: VoiceBroadcastRecorderViewModelType, VoiceBroadcastRecorderViewModelProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private var voiceBroadcastRecorderService: VoiceBroadcastRecorderServiceProtocol
    
    // MARK: Public
    
    // MARK: - Setup
    
    init(details: VoiceBroadcastRecorderDetails,
         recorderService: VoiceBroadcastRecorderServiceProtocol) {
        self.voiceBroadcastRecorderService = recorderService
        let currentRecordingState = VoiceBroadcastRecorderViewModel.currentRecordingState(from: BuildSettings.voiceBroadcastMaxLength)
        super.init(initialViewState: VoiceBroadcastRecorderViewState(details: details,
                                                                     recordingState: .stopped,
                                                                     currentRecordingState: currentRecordingState,
                                                                     bindings: VoiceBroadcastRecorderViewStateBindings()))
        
        self.voiceBroadcastRecorderService.serviceDelegate = self
        process(viewAction: .start)
    }
    
    // MARK: - Public
    
    override func process(viewAction: VoiceBroadcastRecorderViewAction) {
        switch viewAction {
        case .start:
            start()
        case .stop:
            stop()
        case .pause:
            pause()
        case .resume:
            resume()
        }
    }
    
    // MARK: - Private
    private func start() {
        self.state.recordingState = .started
        voiceBroadcastRecorderService.startRecordingVoiceBroadcast()
    }
    
    private func stop() {
        self.state.recordingState = .stopped
        voiceBroadcastRecorderService.stopRecordingVoiceBroadcast()
    }
    
    private func pause() {
        self.state.recordingState = .paused
        voiceBroadcastRecorderService.pauseRecordingVoiceBroadcast()
    }
    
    private func resume() {
        self.state.recordingState = .resumed
        voiceBroadcastRecorderService.resumeRecordingVoiceBroadcast()
    }
    
    private func updateRemainingTime(_ remainingTime: UInt) {
        state.currentRecordingState = VoiceBroadcastRecorderViewModel.currentRecordingState(from: remainingTime)
    }
    
    private static func currentRecordingState(from remainingTime: UInt) -> VoiceBroadcastRecordingState {
        let time = TimeInterval(Double(remainingTime))
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated

        return VoiceBroadcastRecordingState(remainingTime: remainingTime,
                                            remainingTimeLabel: VectorL10n.voiceBroadcastTimeLeft(formatter.string(from: time) ?? "0s"))
    }
}

extension VoiceBroadcastRecorderViewModel: VoiceBroadcastRecorderServiceDelegate {
    func voiceBroadcastRecorderService(_ service: VoiceBroadcastRecorderServiceProtocol, didUpdateState state: VoiceBroadcastRecorderState) {
        self.state.recordingState = state
    }
    
    func voiceBroadcastRecorderService(_ service: VoiceBroadcastRecorderServiceProtocol, didUpdateRemainingTime remainingTime: UInt) {
        self.updateRemainingTime(remainingTime)
    }
}
