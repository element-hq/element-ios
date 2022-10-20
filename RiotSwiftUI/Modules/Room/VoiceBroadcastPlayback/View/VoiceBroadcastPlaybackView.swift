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
    
    private var backgroundColor: Color {
        if viewModel.viewState.playbackState == .playingLive {
            return theme.colors.alert
        }
        return theme.colors.quarterlyContent
    }
    
    // MARK: Public
    
    @ObservedObject var viewModel: VoiceBroadcastPlaybackViewModelImpl.Context
    
    var body: some View {
        let details = viewModel.viewState.details
        
        VStack(alignment: .center, spacing: 16.0) {
            
            HStack {
                Text(details.senderDisplayName ?? "")
                //Text(VectorL10n.voiceBroadcastInTimelineTitle)
                    .font(theme.fonts.bodySB)
                    .foregroundColor(theme.colors.primaryContent)
                
                if viewModel.viewState.broadcastState == .live {
                    Button { viewModel.send(viewAction: .playLive) } label:
                    {
                        HStack {
                            Image(uiImage: Asset.Images.voiceBroadcastLive.image)
                                .renderingMode(.original)
                            Text("Live")
                                .font(theme.fonts.bodySB)
                                .foregroundColor(Color.white)
                        }
                        
                    }
                    .padding(5.0)
                    .background(RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(backgroundColor))
                    .accessibilityIdentifier("liveButton")
                }
            }
    
            if viewModel.viewState.playbackState == .error {
                VoiceBroadcastPlaybackErrorView()
            } else {
                ZStack {
                    if viewModel.viewState.playbackState == .playing ||
                        viewModel.viewState.playbackState == .playingLive {
                        Button { viewModel.send(viewAction: .pause) } label: {
                            Image(uiImage: Asset.Images.voiceBroadcastPause.image)
                                .renderingMode(.original)
                        }
                        .accessibilityIdentifier("pauseButton")
                    } else  {
                        Button {
                            if viewModel.viewState.broadcastState == .live &&
                                viewModel.viewState.playbackState == .stopped {
                                viewModel.send(viewAction: .playLive)
                            } else {
                                viewModel.send(viewAction: .play)
                            }
                        } label: {
                            Image(uiImage: Asset.Images.voiceBroadcastPlay.image)
                                .renderingMode(.original)
                        }
                        .disabled(viewModel.viewState.playbackState == .buffering)
                        .accessibilityIdentifier("playButton")
                    }
                }
                .activityIndicator(show: viewModel.viewState.playbackState == .buffering)
            }

        }
        .padding([.horizontal, .top], 2.0)
        .padding([.bottom])
        .alert(item: $viewModel.alertInfo) { info in
            info.alert
        }
    }
}

// MARK: - Previews

struct VoiceBroadcastPlaybackView_Previews: PreviewProvider {
    static let stateRenderer = MockVoiceBroadcastPlaybackScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
