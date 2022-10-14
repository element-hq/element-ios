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

struct TimelineVoiceBroadcastView: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    @ObservedObject var viewModel: TimelineVoiceBroadcastViewModel.Context
    
    var body: some View {
        let voiceBroadcast = viewModel.viewState.voiceBroadcast
        
        VStack(alignment: .leading, spacing: 16.0) {
            Text("voicebroadcast here")
                .font(theme.fonts.bodySB)
                .foregroundColor(theme.colors.primaryContent)
            
//            VStack(spacing: 24.0) {
//                ForEach(voiceBroadcast.answerOptions) { answerOption in
//                    TimelineVoiceBroadcastAnswerOptionButton(voiceBroadcast: voiceBroadcast, answerOption: answerOption) {
//                        viewModel.send(viewAction: .selectAnswerOptionWithIdentifier(answerOption.id))
//                    }
//                }
//            }
//            .disabled(voiceBroadcast.closed)
//            .fixedSize(horizontal: false, vertical: true)
        }
        .padding([.horizontal, .top], 2.0)
        .padding([.bottom])
        .alert(item: $viewModel.alertInfo) { info in
            info.alert
        }
    }
}

// MARK: - Previews

// TODO: Preview
//struct TimelineVoiceBroadcastView_Previews: PreviewProvider {
//    static let stateRenderer = MockTimelineVoiceBroadcastScreenState.stateRenderer
//    static var previews: some View {
//        stateRenderer.screenGroup()
//    }
//}
