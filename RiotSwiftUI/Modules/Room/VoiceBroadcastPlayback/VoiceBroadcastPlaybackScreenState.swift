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
import SwiftUI

typealias MockVoiceBroadcastPlaybackViewModelType = StateStoreViewModel<VoiceBroadcastPlaybackViewState, VoiceBroadcastPlaybackViewAction>
class MockVoiceBroadcastPlaybackViewModel: MockVoiceBroadcastPlaybackViewModelType, VoiceBroadcastPlaybackViewModelProtocol {    
}

/// Using an enum for the screen allows you define the different state cases with
/// the relevant associated data for each case.
enum MockVoiceBroadcastPlaybackScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case animated
    
    /// The associated screen
    var screenType: Any.Type {
        VoiceBroadcastPlaybackView.self
    }
    
    /// A list of screen state definitions
    static var allCases: [MockVoiceBroadcastPlaybackScreenState] {
        [.animated]
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        
        let details = VoiceBroadcastPlaybackDetails(senderDisplayName: "Alice", avatarData: AvatarInput(mxContentUri: "", matrixItemId: "!fakeroomid:matrix.org", displayName: "The name of the room"))
        let viewModel = MockVoiceBroadcastPlaybackViewModel(initialViewState: VoiceBroadcastPlaybackViewState(details: details, broadcastState: .started,  playbackState: .stopped, playingState: VoiceBroadcastPlayingState(duration: 10.0, isLive: true), bindings: VoiceBroadcastPlaybackViewStateBindings(progress: 0)))
        
        return (
            [false, viewModel],
            AnyView(VoiceBroadcastPlaybackView(viewModel: viewModel.context))
        )
    }
}
