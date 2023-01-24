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

import Combine
import MatrixSDK
import SwiftUI

struct VoiceBroadcastPlaybackCoordinatorParameters {
    let session: MXSession
    let room: MXRoom
    let voiceBroadcastStartEvent: MXEvent
    let voiceBroadcastState: VoiceBroadcastInfoState
    let senderDisplayName: String?
}

final class VoiceBroadcastPlaybackCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: VoiceBroadcastPlaybackCoordinatorParameters
    
    private var viewModel: VoiceBroadcastPlaybackViewModelProtocol!
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    // MARK: - Setup
    
    init(parameters: VoiceBroadcastPlaybackCoordinatorParameters) throws {
        self.parameters = parameters
        
        let voiceBroadcastAggregator = try VoiceBroadcastAggregator(session: parameters.session, room: parameters.room, voiceBroadcastStartEventId: parameters.voiceBroadcastStartEvent.eventId, voiceBroadcastState: parameters.voiceBroadcastState)
        
        let details = VoiceBroadcastPlaybackDetails(senderDisplayName: parameters.senderDisplayName, avatarData: parameters.room.avatarData)
        viewModel = VoiceBroadcastPlaybackViewModel(details: details,
                                                    mediaServiceProvider: VoiceMessageMediaServiceProvider.sharedProvider,
                                                    cacheManager: VoiceMessageAttachmentCacheManager.sharedManager,
                                                    voiceBroadcastAggregator: voiceBroadcastAggregator)

    }
    
    deinit {
        // If init has failed, our viewmodel will be nil.
        viewModel?.context.send(viewAction: .redact)
    }
    
    // MARK: - Public

    func start() { }
    
    func toPresentable() -> UIViewController {
        let view = VoiceBroadcastPlaybackView(viewModel: viewModel.context)
            .environmentObject(AvatarViewModel(avatarService: AvatarService(mediaManager: parameters.session.mediaManager)))
        return VectorHostingController(rootView: view)
    }
    
    func canEndVoiceBroadcast() -> Bool {
        // TODO: VB check is voicebroadcast stopped
        return false
    }
    
    func canEditVoiceBroadcast() -> Bool {
        return false
    }
    
    func endVoiceBroadcast() {}
        
    func pausePlaying() {
        viewModel.context.send(viewAction: .pause)
    }
    
    func pausePlayingInProgressVoiceBroadcast() {
        // Pause the playback if we are playing a live voice broadcast (or waiting for more chunks) 
        if [.playing, .buffering].contains(viewModel.context.viewState.playbackState), viewModel.context.viewState.broadcastState != .stopped {
            viewModel.context.send(viewAction: .pause)
        }
    }
}
