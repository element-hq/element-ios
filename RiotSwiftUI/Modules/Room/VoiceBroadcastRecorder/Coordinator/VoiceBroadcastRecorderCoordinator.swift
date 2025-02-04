// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct VoiceBroadcastRecorderCoordinatorParameters {
    let session: MXSession
    let room: MXRoom
    let voiceBroadcastStartEvent: MXEvent
    let senderDisplayName: String?
}

final class VoiceBroadcastRecorderCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: VoiceBroadcastRecorderCoordinatorParameters
    
    private var voiceBroadcastRecorderService: VoiceBroadcastRecorderServiceProtocol
    private var voiceBroadcastRecorderViewModel: VoiceBroadcastRecorderViewModelProtocol
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
        
    // MARK: - Setup
    
    init(parameters: VoiceBroadcastRecorderCoordinatorParameters) {
        self.parameters = parameters
        
        voiceBroadcastRecorderService = VoiceBroadcastRecorderService(session: parameters.session, roomId: parameters.room.matrixItemId)
        
        let details = VoiceBroadcastRecorderDetails(senderDisplayName: parameters.senderDisplayName, avatarData: parameters.room.avatarData)
        let viewModel = VoiceBroadcastRecorderViewModel(details: details,
                                                        recorderService: voiceBroadcastRecorderService)
        voiceBroadcastRecorderViewModel = viewModel
    }
    
    deinit {
        voiceBroadcastRecorderService.cancelRecordingVoiceBroadcast()
    }

    // MARK: - Public

    func start() { }
    
    func toPresentable() -> UIViewController {
        let view = VoiceBroadcastRecorderView(viewModel: voiceBroadcastRecorderViewModel.context)
            .environmentObject(AvatarViewModel(avatarService: AvatarService(mediaManager: parameters.session.mediaManager)))

        return VectorHostingController(rootView: view)
    }
    
    func pauseRecording() {
        voiceBroadcastRecorderViewModel.context.send(viewAction: .pause)
    }
    
    func pauseRecordingOnError() {
        voiceBroadcastRecorderViewModel.context.send(viewAction: .pauseOnError)
    }
    
    func isVoiceBroadcastRecording() -> Bool {
        return voiceBroadcastRecorderService.isRecording
    }

    // MARK: - Private
}
