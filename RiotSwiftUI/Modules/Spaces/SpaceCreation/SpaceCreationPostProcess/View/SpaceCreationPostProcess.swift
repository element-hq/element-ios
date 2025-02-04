// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationPostProcess SpaceCreationPostProcess
//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
