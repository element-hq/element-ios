// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

// TODO: To remove
// VoiceBroadcastPlaybackViewModel must be revisited in order to not depend on MatrixSDK
#if canImport(MatrixSDK)
typealias VoiceBroadcastPlaybackViewModelImpl = VoiceBroadcastPlaybackViewModel
#else
typealias VoiceBroadcastPlaybackViewModelImpl = MockVoiceBroadcastPlaybackViewModel
#endif

struct VoiceBroadcastPlaybackView: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    @State private var bufferingSpinnerRotationValue = 0.0
    
    private var backgroundColor: Color {
        if viewModel.viewState.broadcastState != .paused {
            return theme.colors.alert
        }
        return theme.colors.quarterlyContent
    }
    
    // MARK: Public
    
    @ObservedObject var viewModel: VoiceBroadcastPlaybackViewModelImpl.Context
    
    var body: some View {
        let details = viewModel.viewState.details
        
        VStack(alignment: .center) {
            
            HStack (alignment: .top) {
                AvatarImage(avatarData: viewModel.viewState.details.avatarData, size: .small)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(details.avatarData.displayName ?? details.avatarData.matrixItemId)
                        .font(theme.fonts.bodySB)
                        .foregroundColor(theme.colors.primaryContent)
                    Label {
                        Text(details.senderDisplayName ?? details.avatarData.matrixItemId)
                            .foregroundColor(theme.colors.secondaryContent)
                            .font(theme.fonts.caption1)
                    } icon: {
                        Image(uiImage: Asset.Images.voiceBroadcastTileMic.image)
                    }
                    if viewModel.viewState.playbackState != .buffering {
                        Label {
                            Text(VectorL10n.voiceBroadcastTile)
                                .foregroundColor(theme.colors.secondaryContent)
                                .font(theme.fonts.caption1)
                        } icon: {
                            Image(uiImage: Asset.Images.voiceBroadcastTileLive.image)
                        }
                    } else {
                        Label {
                            Text(VectorL10n.voiceBroadcastBuffering)
                                .foregroundColor(theme.colors.secondaryContent)
                                .font(theme.fonts.caption1)
                        } icon: {
                            Image(uiImage: Asset.Images.voiceBroadcastSpinner.image)
                                .frame(width: 16.0, height: 16.0)
                                .rotationEffect(Angle.degrees(bufferingSpinnerRotationValue))
                                .onAppear {
                                    let baseAnimation = Animation.linear(duration: 1.0).repeatForever(autoreverses: false)
                                    withAnimation(baseAnimation) {
                                        bufferingSpinnerRotationValue = 360.0
                                    }
                                }
                                .onDisappear {
                                    bufferingSpinnerRotationValue = 0.0
                                }
                        }
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
                                
                if viewModel.viewState.broadcastState != .stopped {
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
                    .accessibilityIdentifier("liveLabel")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(EdgeInsets(top: 0.0, leading: 0.0, bottom: 4.0, trailing: 0.0))
            
            if viewModel.viewState.decryptionState.errorCount > 0 {
                VoiceBroadcastPlaybackDecryptionErrorView()
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("decryptionErrorView")
            }
            else if viewModel.viewState.showPlaybackError {
                VoiceBroadcastPlaybackErrorView()
            } else {
                HStack (spacing: 34.0) {
                    if viewModel.viewState.playingState.canMoveBackward {
                        Button {
                            viewModel.send(viewAction: .backward)
                        } label: {
                            Image(uiImage: Asset.Images.voiceBroadcastBackward30s.image)
                                .renderingMode(.original)
                        }
                        .accessibilityIdentifier("backwardButton")
                    } else {
                        Spacer().frame(width: 25.0)
                    }
                    
                    if viewModel.viewState.playbackState == .playing || viewModel.viewState.playbackState == .buffering {
                        Button { viewModel.send(viewAction: .pause) } label: {
                            Image(uiImage: Asset.Images.voiceBroadcastPause.image)
                                .renderingMode(.original)
                        }
                        .accessibilityIdentifier("pauseButton")
                    } else {
                        Button { viewModel.send(viewAction: .play) } label: {
                            Image(uiImage: Asset.Images.voiceBroadcastPlay.image)
                                .renderingMode(.original)
                        }
                        .disabled(viewModel.viewState.playbackState == .buffering)
                        .accessibilityIdentifier("playButton")
                    }
                    
                    if viewModel.viewState.playingState.canMoveForward {
                        Button {
                            viewModel.send(viewAction: .forward)
                        } label: {
                            Image(uiImage: Asset.Images.voiceBroadcastForward30s.image)
                                .renderingMode(.original)
                        }
                        .accessibilityIdentifier("forwardButton")
                    } else {
                        Spacer().frame(width: 25.0)
                    }
                }
                .padding(EdgeInsets(top: 10.0, leading: 0.0, bottom: 10.0, trailing: 0.0))
            }
            
            VoiceBroadcastSlider(value: $viewModel.progress,
                                 minValue: 0.0,
                                 maxValue: viewModel.viewState.playingState.duration) { didChange in
                viewModel.send(viewAction: .sliderChange(didChange: didChange))
            }
            
            HStack {
                Text(viewModel.viewState.playingState.elapsedTimeLabel ?? "")
                    .foregroundColor(theme.colors.secondaryContent)
                    .font(theme.fonts.caption1)
                    .padding(EdgeInsets(top: -8.0, leading: 4.0, bottom: 0.0, trailing: 0.0))
                Spacer()
                Text(viewModel.viewState.playingState.remainingTimeLabel ?? "")
                    .foregroundColor(theme.colors.secondaryContent)
                    .font(theme.fonts.caption1)
                    .padding(EdgeInsets(top: -8.0, leading: 0.0, bottom: 0.0, trailing: 4.0))
            }
        }
        .padding(EdgeInsets(top: 12.0, leading: 4.0, bottom: 12.0, trailing: 4.0))
    }
}

// MARK: - Previews

struct VoiceBroadcastPlaybackView_Previews: PreviewProvider {
    static let stateRenderer = MockVoiceBroadcastPlaybackScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
