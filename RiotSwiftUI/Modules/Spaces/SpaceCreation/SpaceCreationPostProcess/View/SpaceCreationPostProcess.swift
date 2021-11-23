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

@available(iOS 14.0, *)
struct SpaceCreationPostProcess: View {

    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    @ObservedObject var viewModel: SpaceCreationPostProcessViewModel.Context
    
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 13) {
                ProgressView()
                    .isHidden(viewModel.viewState.isFinished)
                    .scaleEffect(1.5, anchor: .center)
                    .progressViewStyle(CircularProgressViewStyle(tint: theme.colors.secondaryContent))
                Text(VectorL10n.spacesCreationPostProcessCreatingSpace)
                    .font(theme.fonts.calloutSB)
                    .foregroundColor(theme.colors.secondaryContent)
            }
            Spacer()
            VStack(alignment: .leading, spacing: 11) {
                ForEach(viewModel.viewState.tasks.indices) { index in
                    SpaceCreationPostProcessItem(title: viewModel.viewState.tasks[index].title, state: viewModel.viewState.tasks[index].state)
                }
            }
            Spacer()
            HStack {
                ThemableButton(icon: nil, title: VectorL10n.done) {
                    viewModel.send(viewAction: .cancel)
                }
                ThemableButton(icon: nil, title: VectorL10n.retry) {
                    viewModel.send(viewAction: .retry)
                }
            }
            .isHidden(!viewModel.viewState.isFinished || viewModel.viewState.errorCount == 0)
        }
        .animation(.easeIn(duration: 0.2), value: viewModel.viewState.errorCount)
        .padding(EdgeInsets(top: 24, leading: 16, bottom: 24, trailing: 16))
        .navigationBarHidden(true)
        .background(theme.colors.background)
        .frame(maxHeight: .infinity)
        .onAppear() {
            viewModel.send(viewAction: .runTasks)
        }
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct SpaceCreationPostProcess_Previews: PreviewProvider {
    static let stateRenderer = MockSpaceCreationPostProcessScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true).theme(.light).preferredColorScheme(.light)
        stateRenderer.screenGroup(addNavigation: true).theme(.dark).preferredColorScheme(.dark)
    }
}
