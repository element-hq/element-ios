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

    // MARK: - Public

    func start() { }
    
    func toPresentable() -> UIViewController {
        let view = VoiceBroadcastRecorderView(viewModel: voiceBroadcastRecorderViewModel.context)
        return VectorHostingController(rootView: view)
    }
    
    func pauseRecording() {
        voiceBroadcastRecorderViewModel.context.send(viewAction: .pause)
    }

    // MARK: - Private
}
