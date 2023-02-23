// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationPostProcess SpaceCreationPostProcess
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

struct SpaceCreationPostProcess: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    @ObservedObject var viewModel: SpaceCreationPostProcessViewModel.Context
    
    var body: some View {
        VStack {
            Spacer()
            headerView
            Spacer()
            tasksList
            Spacer()
            buttonsPanel
        }
        .animation(.easeIn(duration: 0.2), value: viewModel.viewState.errorCount)
        .padding(EdgeInsets(top: 0, leading: 16, bottom: 24, trailing: 16))
        .navigationBarHidden(true)
        .background(theme.colors.background.ignoresSafeArea())
        .frame(maxHeight: .infinity)
        .onAppear {
            viewModel.send(viewAction: .runTasks)
        }
    }
    
    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 13) {
            avatarView
            Text(VectorL10n.spacesCreationPostProcessCreatingSpace)
                .font(theme.fonts.calloutSB)
                .foregroundColor(theme.colors.secondaryContent)
        }
    }
    
    @ViewBuilder
    private var tasksList: some View {
        VStack(alignment: .leading, spacing: 11) {
            ForEach(viewModel.viewState.tasks.indices, id: \.self) { index in
                SpaceCreationPostProcessItem(title: viewModel.viewState.tasks[index].title, state: viewModel.viewState.tasks[index].state)
            }
        }
    }
    
    @ViewBuilder
    private var buttonsPanel: some View {
        HStack {
            ThemableButton(icon: nil, title: VectorL10n.cancel) {
                viewModel.send(viewAction: .cancel)
            }
            ThemableButton(icon: nil, title: VectorL10n.retry) {
                viewModel.send(viewAction: .retry)
            }
        }
        .isHidden(!viewModel.viewState.isFinished || viewModel.viewState.errorCount == 0)
    }

    @ViewBuilder
    private var avatarView: some View {
        ZStack {
            SpaceAvatarImage(mxContentUri: viewModel.viewState.avatar.mxContentUri, matrixItemId: viewModel.viewState.avatar.matrixItemId, displayName: viewModel.viewState.avatar.displayName, size: .xLarge)
                .padding(6)
            if let image = viewModel.viewState.avatarImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 52, height: 52, alignment: .center)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

// MARK: - Previews

struct SpaceCreationPostProcess_Previews: PreviewProvider {
    static let stateRenderer = MockSpaceCreationPostProcessScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true).theme(.light).preferredColorScheme(.light)
        stateRenderer.screenGroup(addNavigation: true).theme(.dark).preferredColorScheme(.dark)
    }
}
