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

struct PollHistoryDetail: View {
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    @ObservedObject var viewModel: PollHistoryDetailViewModel.Context
    var contentPoll: any View
    
    var body: some View {
        navigation
    }
    
    private var navigation: some View {
        if #available(iOS 16.0, *) {
            return NavigationStack {
                content
            }
        } else {
            return NavigationView {
                content
            }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(DateFormatter.pollShortDateFormatter.string(from: viewModel.viewState.pollStartDate))
                    .foregroundColor(theme.colors.tertiaryContent)
                    .font(theme.fonts.caption1)
                    .padding([.top])
                    .accessibilityIdentifier("PollHistoryDetail.date")
                AnyView(contentPoll)
                    .navigationTitle(navigationTitle)
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden(true)
                    .navigationBarItems(leading: backButton, trailing: doneButton)
                viewInTimeline
            }
        }
        .padding([.horizontal], 16)
        .padding([.top, .bottom])
        .background(theme.colors.background.ignoresSafeArea())
    }
    
    private var backButton: some View {
        Button(action: {
            viewModel.send(viewAction: .dismiss)
        }) {
            Image(systemName: "chevron.left")
                .aspectRatio(contentMode: .fit)
                .foregroundColor(theme.colors.accent)
        }
    }

    private var doneButton: some View {
        Button {
            viewModel.send(viewAction: .dismiss)
        } label: {
            Text(VectorL10n.done)
        }
        .accentColor(theme.colors.accent)
    }
    
    private var viewInTimeline: some View {
        Button {
            viewModel.send(viewAction: .viewInTimeline)
        } label: {
            Text(VectorL10n.pollHistoryDetailViewInTimeline)
        }
        .accentColor(theme.colors.accent)
        .accessibilityIdentifier("PollHistoryDetail.viewInTimeLineButton")
    }
    
    private var navigationTitle: String {
        if viewModel.viewState.isPollClosed {
            return VectorL10n.pollHistoryPastSegmentTitle
        } else {
            return VectorL10n.pollHistoryActiveSegmentTitle
        }
    }
}

// MARK: - Previews

struct PollHistoryDetail_Previews: PreviewProvider {
    static let stateRenderer = MockPollHistoryDetailScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
