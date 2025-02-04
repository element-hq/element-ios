// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
        let viewModel = MockVoiceBroadcastPlaybackViewModel(initialViewState: VoiceBroadcastPlaybackViewState(details: details, broadcastState: .started,  playbackState: .stopped, playingState: VoiceBroadcastPlayingState(duration: 10.0, isLive: true, canMoveForward: false, canMoveBackward: false), bindings: VoiceBroadcastPlaybackViewStateBindings(progress: 0), decryptionState: VoiceBroadcastPlaybackDecryptionState(errorCount: 0), showPlaybackError: false))
        
        return (
            [false, viewModel],
            AnyView(VoiceBroadcastPlaybackView(viewModel: viewModel.context)
                .environmentObject(AvatarViewModel.withMockedServices()))
        )
    }
}
