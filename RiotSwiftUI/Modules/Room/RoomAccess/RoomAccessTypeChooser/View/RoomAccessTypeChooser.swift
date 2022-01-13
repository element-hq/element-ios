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
struct RoomAccessTypeChooser: View {
    
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    @ObservedObject var viewModel: RoomAccessTypeChooserViewModelType.Context
    let roomName: String
    
    var body: some View {
        listContent
            .modifier(WaitOverlay(
                        allowUserInteraction: false,
                        message: $viewModel.waitingMessage,
                        isLoading: $viewModel.isLoading))
            .modal(withStyle: .overFullScreen,
                   modalTransitionStyle: .crossDissolve,
                   id: "RoomAccessTypeChooser-RoomAccessTypeChooserUpgradeRoomAlert",
                   isPresented: $viewModel.showUpgradeRoomAlert) {
                RoomAccessTypeChooserUpgradeRoomAlert(viewModel: viewModel)
            }
            .navigationTitle(VectorL10n.roomAccessSettingsScreenNavTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(VectorL10n.cancel) {
                        viewModel.send(viewAction: .cancel)
                    }
                    .disabled(viewModel.isLoading)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(VectorL10n.done) {
                        viewModel.send(viewAction: .done)
                    }
                    .disabled(viewModel.isLoading)
                }
            }
    }
    
    // MARK: Private
    
    @ViewBuilder
    private var listContent: some View {
        ScrollView{
            VStack(alignment: .leading) {
                Text(VectorL10n.roomAccessSettingsScreenTitle)
                    .foregroundColor(theme.colors.primaryContent)
                    .font(theme.fonts.bodySB)
                    .padding(.top, 24)
                Text(VectorL10n.roomAccessSettingsScreenMessage(roomName))
                    .foregroundColor(theme.colors.secondaryContent)
                    .font(theme.fonts.callout)
                    .padding(.top, 8)
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.viewState.accessItems) { item in
                        RoomAccessTypeChooserRow(isSelected: item.isSelected, title: item.title, message: item.detail, badgeText: item.badgeText)
                            .onTapGesture {
                                viewModel.send(viewAction: .didSelectAccessType(item.id))
                            }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 30)
            }
            .padding(.horizontal)
        }.background(theme.colors.background)
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct RoomAccessTypeChooser_Previews: PreviewProvider {
    
    static let stateRenderer = MockRoomAccessTypeChooserScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true)
            .theme(.light).preferredColorScheme(.light)
        stateRenderer.screenGroup(addNavigation: true)
            .theme(.dark).preferredColorScheme(.dark)
    }
}
