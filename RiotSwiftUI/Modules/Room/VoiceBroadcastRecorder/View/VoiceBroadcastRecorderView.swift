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

import SwiftUI

struct VoiceBroadcastRecorderView: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    @ObservedObject var viewModel: VoiceBroadcastRecorderViewModel.Context
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16.0) {
            Text(VectorL10n.voiceBroadcastInTimelineTitle)
                .font(theme.fonts.bodySB)
                .foregroundColor(theme.colors.primaryContent)
            
            HStack(alignment: .top, spacing: 16.0) {
                Button {
                    // FIXME: Manage record in progress case
                    viewModel.send(viewAction: .start)
                } label: {
                    // FIXME: Manage record in progress case
                    Image("voice_broadcast_record")
                        .renderingMode(.original)
                }
                .accessibilityIdentifier("recordButton")
                
                Button {
                    // FIXME: Manage resume case
                    viewModel.send(viewAction: .pause)
                } label: {
                    Image("voice_broadcast_record_pause")
                        .renderingMode(.original)
                }
                .accessibilityIdentifier("pauseButton")
            }

        }
        .padding([.horizontal, .top], 2.0)
        .padding([.bottom])
    }
    
//    private func updateRecordingStatus() {
//        switch viewModel.viewState.recordingState {
//        case .started:
//            viewModel.send(viewAction: .stop)
//        case .paused:
//            viewModel.send(viewAction: .resume)
//        case .stopped:
//            viewModel.send(viewAction: .start)
//        case .resumed:
//            viewModel.send(viewAction: .pause)
//        }
//    }
}


// MARK: - Previews

struct VoiceBroadcastRecorderView_Previews: PreviewProvider {
    static let stateRenderer = MockVoiceBroadcastRecorderScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
