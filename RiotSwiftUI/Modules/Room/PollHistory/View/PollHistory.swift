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
    
    var bindings: PollHistoryViewBindings {
        viewModel.viewState.bindings
    }
    
    var body: some View {
        VStack {
            HStack {
                SegmentedPicker(
                    segments: [
                        ("Active Polls", PollHistoryMode.active),
                        ("Past Pools", PollHistoryMode.past)
                    ],
                    selection: $viewModel.mode,
                    interSegmentSpacing: 14
                )
                Spacer()
            }
            .padding(.horizontal, 16)
            
            ScrollView {
                LazyVStack(spacing: 32) {
                    ForEach(0..<10) { index in
                        PollListItem(data: .init(startDate: Date(), question: "Poll question number \(index)"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button {
                        #warning("handle action")
                    } label: {
                        Text("Load more polls")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)
                .padding(.top, 32)
            }
        }
        .padding(.top, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.background.ignoresSafeArea())
        .accentColor(theme.colors.accent)
    }
}

// MARK: - Previews

struct PollHistory_Previews: PreviewProvider {
    static let stateRenderer = MockPollHistoryScreenState.stateRenderer
    
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
