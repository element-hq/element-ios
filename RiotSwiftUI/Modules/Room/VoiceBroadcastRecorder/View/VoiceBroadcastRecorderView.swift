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
    
    @State private var showingStopAlert = false
    
    private var backgroundColor: Color {
        if viewModel.viewState.recordingState != .paused {
            return theme.colors.alert
        }
        return theme.colors.quarterlyContent
    }
    
    // MARK: Public
    
    @ObservedObject var viewModel: VoiceBroadcastRecorderViewModel.Context
    
    var body: some View {
        let details = viewModel.viewState.details
        
        VStack(alignment: .center) {
            
            HStack(alignment: .top) {
                AvatarImage(avatarData: viewModel.viewState.details.avatarData, size: .xSmall)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(details.avatarData.displayName ?? details.avatarData.matrixItemId)
                        .font(theme.fonts.bodySB)
                        .foregroundColor(theme.colors.primaryContent)
                    Label {
                        Text(VectorL10n.voiceBroadcastTile)
                            .foregroundColor(theme.colors.secondaryContent)
                            .font(theme.fonts.caption1)
                    } icon: {
                        Image(uiImage: Asset.Images.voiceBroadcastTileLive.image)
                    }
                    
                    Label {
                        Text(viewModel.viewState.currentRecordingState.remainingTimeLabel)
                            .foregroundColor(theme.colors.secondaryContent)
                            .font(theme.fonts.caption1)
                    } icon: {
                        Image(uiImage: Asset.Images.voiceBroadcastTimeLeft.image)
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
                
                Label {
                    Text(VectorL10n.voiceBroadcastLive)
                        .font(theme.fonts.caption1SB)
                        .foregroundColor(Color.white)
                } icon: {
                    Image(uiImage: Asset.Images.voiceBroadcastLive.image)
                }
                .padding(.horizontal, 5)
                .background(RoundedRectangle(cornerRadius: 4, style: .continuous).fill(backgroundColor))
                .accessibilityIdentifier("liveButton")
            }
            
            HStack(alignment: .top, spacing: 16.0) {
                Button {
                    switch viewModel.viewState.recordingState {
                    case .started, .resumed:
                        viewModel.send(viewAction: .pause)
                    case .stopped:
                        viewModel.send(viewAction: .start)
                    case .paused:
                        viewModel.send(viewAction: .resume)
                    }
                } label: {
                    if viewModel.viewState.recordingState == .started || viewModel.viewState.recordingState == .resumed {
                        Image("voice_broadcast_record_pause")
                            .renderingMode(.original)
                    } else {
                        Image("voice_broadcast_record")
                            .renderingMode(.original)
                    }
                }
                .accessibilityIdentifier("recordButton")
                
                Button {
                    showingStopAlert = true
                } label: {
                    Image("voice_broadcast_stop")
                        .renderingMode(.original)
                }
                .alert(isPresented:$showingStopAlert) {
                    Alert(title: Text(VectorL10n.voiceBroadcastStopAlertTitle),
                          message: Text(VectorL10n.voiceBroadcastStopAlertDescription),
                          primaryButton: .cancel(),
                          secondaryButton: .default(Text(VectorL10n.voiceBroadcastStopAlertAgreeButton),
                                                    action: {
                        viewModel.send(viewAction: .stop)
                    }))
                }
                .accessibilityIdentifier("stopButton")
                .disabled(viewModel.viewState.recordingState == .stopped)
                .mask(Color.black.opacity(viewModel.viewState.recordingState == .stopped ? 0.3 : 1.0))
            }
        }
        .padding([.horizontal, .top], 2.0)
        .padding([.bottom])
    }
}


// MARK: - Previews

struct VoiceBroadcastRecorderView_Previews: PreviewProvider {
    static let stateRenderer = MockVoiceBroadcastRecorderScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
