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

typealias TimelineVoiceBroadcastViewModelType = StateStoreViewModel<TimelineVoiceBroadcastViewState, TimelineVoiceBroadcastViewAction>

class TimelineVoiceBroadcastViewModel: TimelineVoiceBroadcastViewModelType, TimelineVoiceBroadcastViewModelProtocol {
    
    // MARK: - Properties

    // MARK: Private
    
    // MARK: Public
    
    var completion: ((TimelineVoiceBroadcastViewModelResult) -> Void)?
    
    // MARK: - Setup
    
    init(timelineVoiceBroadcastDetails: TimelineVoiceBroadcastDetails) {
        super.init(initialViewState: TimelineVoiceBroadcastViewState(voiceBroadcast: timelineVoiceBroadcastDetails, bindings: TimelineVoiceBroadcastViewStateBindings()))
    }
    
    // MARK: - Public
    
    override func process(viewAction: TimelineVoiceBroadcastViewAction) {
        switch viewAction {
        case .play:
            play()
        case .pause:
            pause()
        }
    }
    
    /// Listen voice broadcast
    private func play() {
        completion?(.played)
    }
    
    /// Stop voice broadcast
    private func pause() {
        completion?(.paused)
    }
    
    // MARK: - TimelineVoiceBroadcastViewModelProtocol
    
    func updateWithVoiceBroadcastDetails(_ voiceBroadcastDetails: TimelineVoiceBroadcastDetails) {
        state.voiceBroadcast = voiceBroadcastDetails
    }
}
