//
// Copyright 2021 New Vector Ltd
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

struct PollHistory: View {
    @Environment(\.theme) private var theme
    
    @ObservedObject var viewModel: PollHistoryViewModel.Context
    
    var body: some View {
        VStack {
            SegmentedPicker(
                segments: PollHistoryMode.allCases,
                selection: $viewModel.mode,
                interSegmentSpacing: 14
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            
            content
        }
        .padding(.top, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.background.ignoresSafeArea())
        .accentColor(theme.colors.accent)
        .navigationTitle(VectorL10n.pollHistoryTitle)
        .onAppear {
            viewModel.send(viewAction: .viewAppeared)
        }
        .onChange(of: viewModel.mode) { _ in
            viewModel.send(viewAction: .segmentDidChange)
        }
        .alert(item: $viewModel.alertInfo) {
            $0.alert
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if viewModel.viewState.polls == nil {
            loadingView
        } else if viewModel.viewState.polls?.isEmpty == true {
            noPollsView
        } else {
            pollListView
        }
    }
    
    private var pollListView: some View {
        ScrollView {
            LazyVStack(spacing: 32) {
                ForEach(viewModel.viewState.polls ?? []) { pollData in
                    Button(action: {
                        viewModel.send(viewAction: .showPollDetail(poll: pollData))
                    }) {
                        PollListItem(pollData: pollData)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                loadMoreButton
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 32)
            .padding(.horizontal, 16)
        }
    }
    
    @ViewBuilder
    private var loadMoreButton: some View {
        if viewModel.viewState.canLoadMoreContent {
            HStack(spacing: 8) {
                if viewModel.viewState.isLoading {
                    spinner
                }
                
                Button {
                    viewModel.send(viewAction: .loadMoreContent)
                } label: {
                    Text(VectorL10n.pollHistoryLoadMore)
                        .font(theme.fonts.body)
                }
                .accessibilityIdentifier("PollHistory.loadMore")
                .disabled(viewModel.viewState.isLoading)
            }
        }
    }
    
    private var spinner: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
    }
    
    private var noPollsView: some View {
        VStack(spacing: 32) {
            Text(viewModel.emptyPollsText)
                .font(theme.fonts.body)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.secondaryContent)
                .padding(.horizontal, 16)
                .accessibilityIdentifier("PollHistory.emptyText")

            if viewModel.viewState.canLoadMoreContent {
                loadMoreButton
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    private var loadingView: some View {
        HStack(spacing: 8) {
            spinner
            
            Text(VectorL10n.pollHistoryLoadingText)
                .font(theme.fonts.body)
                .foregroundColor(theme.colors.secondaryContent)
                .frame(maxHeight: .infinity)
                .accessibilityIdentifier("PollHistory.loadingText")
        }
        .padding(.horizontal, 16)
    }
}

extension PollHistoryMode: CustomStringConvertible {
    var description: String {
        switch self {
        case .active:
            return VectorL10n.pollHistoryActiveSegmentTitle
        case .past:
            return VectorL10n.pollHistoryPastSegmentTitle
        }
    }
}

// MARK: - Previews

struct PollHistory_Previews: PreviewProvider {
    static let stateRenderer = MockPollHistoryScreenState.stateRenderer
    
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
