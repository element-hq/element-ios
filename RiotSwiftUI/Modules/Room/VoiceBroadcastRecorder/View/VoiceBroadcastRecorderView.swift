// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct VoiceBroadcastRecorderView: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    @State private var showingStopAlert = false
    
    private var backgroundColor: Color {
        if viewModel.viewState.recordingState != .paused, viewModel.viewState.recordingState != .error {
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
                AvatarImage(avatarData: viewModel.viewState.details.avatarData, size: .small)
                
                VStack(alignment: .leading, spacing: 3) {
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
                        .padding(.leading, -4)
                } icon: {
                    Image(uiImage: Asset.Images.voiceBroadcastLive.image)
                }
                .padding(EdgeInsets(top: 2.0, leading: 4.0, bottom: 2.0, trailing: 4.0))
                .background(RoundedRectangle(cornerRadius: 2, style: .continuous).fill(backgroundColor))
                .accessibilityIdentifier("liveButton")
            }
            
            if viewModel.viewState.recordingState == .error {
                VoiceBroadcastRecorderConnectionErrorView()
            } else {
                HStack(alignment: .top, spacing: 34.0) {
                    Button {
                        switch viewModel.viewState.recordingState {
                        case .started, .resumed:
                            viewModel.send(viewAction: .pause)
                        case .stopped:
                            viewModel.send(viewAction: .start)
                        case .paused:
                            viewModel.send(viewAction: .resume)
                        case .error:
                            break
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
                .padding(EdgeInsets(top: 10.0, leading: 0.0, bottom: 10.0, trailing: 0.0))
            }
        }
        .padding(EdgeInsets(top: 12.0, leading: 4.0, bottom: 12.0, trailing: 4.0))
    }
}


// MARK: - Previews

struct VoiceBroadcastRecorderView_Previews: PreviewProvider {
    static let stateRenderer = MockVoiceBroadcastRecorderScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
