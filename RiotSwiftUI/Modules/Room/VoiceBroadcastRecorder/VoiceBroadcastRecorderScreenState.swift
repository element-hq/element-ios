// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

typealias MockVoiceBroadcastRecorderViewModelType = StateStoreViewModel<VoiceBroadcastRecorderViewState, VoiceBroadcastRecorderViewAction>
class MockVoiceBroadcastRecorderViewModel: MockVoiceBroadcastRecorderViewModelType, VoiceBroadcastRecorderViewModelProtocol {
    
}

/// Using an enum for the screen allows you define the different state cases with
/// the relevant associated data for each case.
enum MockVoiceBroadcastRecorderScreenState: MockScreenState, CaseIterable {
    
    var screenType: Any.Type {
        VoiceBroadcastRecorderView.self
    }
    
    var screenView: ([Any], AnyView) {
        let details = VoiceBroadcastRecorderDetails(senderDisplayName: "", avatarData: AvatarInput(mxContentUri: "", matrixItemId: "!fakeroomid:matrix.org", displayName: "The name of the room"))
        let recordingState = VoiceBroadcastRecordingState(remainingTime: BuildSettings.voiceBroadcastMaxLength, remainingTimeLabel: "1h 20m 47s left")
        let viewModel = MockVoiceBroadcastRecorderViewModel(initialViewState: VoiceBroadcastRecorderViewState(details: details, recordingState: .started, currentRecordingState: recordingState, bindings: VoiceBroadcastRecorderViewStateBindings()))
        
        return (
            [false, viewModel],
            AnyView(VoiceBroadcastRecorderView(viewModel: viewModel.context))
        )
    }
}
