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
            
            if viewModel.viewState.polls.isEmpty {
                noPollsView
            } else {
                pollListView
            }
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
    }
    
    private var pollListView: some View {
        ScrollView {
            LazyVStack(spacing: 32) {
                let enumeratedPolls = Array(viewModel.viewState.polls.enumerated())
                
                ForEach(enumeratedPolls, id: \.offset) { _, pollData in
                    PollListItem(pollData: pollData)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Button {
                    #warning("handle action")
                } label: {
                    Text("Load more polls")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 32)
            .padding(.horizontal, 16)
        }
    }
    
    private var noPollsView: some View {
        Text(viewModel.mode == .active ? VectorL10n.pollHistoryNoActivePollText : VectorL10n.pollHistoryNoPastPollText)
            .font(theme.fonts.body)
            .foregroundColor(theme.colors.secondaryContent)
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 16)
            .accessibilityLabel("PollHistory.emptyText")
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
