// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
        case .pauseOnError:
            pauseOnError()
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
    
    private func pauseOnError() {
        voiceBroadcastRecorderService.pauseOnErrorRecordingVoiceBroadcast()
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
