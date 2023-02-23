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
