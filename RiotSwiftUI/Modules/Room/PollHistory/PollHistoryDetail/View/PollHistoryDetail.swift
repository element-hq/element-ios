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
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    @ObservedObject var viewModel: PollHistoryDetailViewModel.Context
    
    var body: some View {
        navigation
            .padding([.horizontal], 16)
            .padding([.top, .bottom])
            .background(theme.colors.background.ignoresSafeArea())
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
        let timelineViewModel = viewModel.viewState.timelineViewModel
        return TimelinePollView(viewModel: timelineViewModel.context)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: btnBack)
    }
    
    private var btnBack : some View { Button(action: {
        viewModel.send(viewAction: .dismiss)
        }) {
            HStack {
            Image(systemName: "xmark") //"chevron.left"
                .aspectRatio(contentMode: .fit)
                .foregroundColor(theme.colors.accent)
            }
        }
    }
    
    private var navigationTitle: String {
        let poll = viewModel.viewState.poll
        if poll.closed {
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
