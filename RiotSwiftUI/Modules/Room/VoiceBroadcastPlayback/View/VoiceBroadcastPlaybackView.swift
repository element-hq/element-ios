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
        if viewModel.viewState.playingState.isLive {
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
                AvatarImage(avatarData: viewModel.viewState.details.avatarData, size: .xSmall)
                
                VStack(alignment: .leading, spacing: 0) {
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
                    } icon: {
                        Image(uiImage: Asset.Images.voiceBroadcastLive.image)
                    }
                    .padding(.horizontal, 5)
                    .background(RoundedRectangle(cornerRadius: 4, style: .continuous).fill(backgroundColor))
                    .accessibilityIdentifier("liveLabel")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if viewModel.viewState.playbackState == .error {
                VoiceBroadcastPlaybackErrorView()
            } else {
                ZStack {
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
                }
            }
            
            Slider(value: $viewModel.progress, in: 0...viewModel.viewState.playingState.duration) {
                Text("Slider")
            } minimumValueLabel: {
                Text("")
            } maximumValueLabel: {
                Text(viewModel.viewState.playingState.durationLabel ?? "").font(.body)
            } onEditingChanged: { didChange in
                viewModel.send(viewAction: .sliderChange(didChange: didChange))
            }
        }
        .padding([.horizontal, .top], 2.0)
        .padding([.bottom])
    }
}

// MARK: - Previews

struct VoiceBroadcastPlaybackView_Previews: PreviewProvider {
    static let stateRenderer = MockVoiceBroadcastPlaybackScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
