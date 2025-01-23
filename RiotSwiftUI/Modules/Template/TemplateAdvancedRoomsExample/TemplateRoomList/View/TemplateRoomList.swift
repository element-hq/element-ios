//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct TemplateRoomList: View {
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    @ObservedObject var viewModel: TemplateRoomListViewModelType.Context
    
    var body: some View {
        listContent
            .navigationTitle("Unencrypted Rooms")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(VectorL10n.done) {
                        viewModel.send(viewAction: .done)
                    }
                }
            }
    }
    
    @ViewBuilder
    var listContent: some View {
        if viewModel.viewState.rooms.isEmpty {
            Text("No Rooms")
                .foregroundColor(theme.colors.primaryContent)
                .accessibility(identifier: "errorMessage")
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.viewState.rooms) { room in
                        Button {
                            viewModel.send(viewAction: .didSelectRoom(room.id))
                        } label: {
                            TemplateRoomListRow(avatar: room.avatar, displayName: room.displayName)
                        }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }.background(theme.colors.background)
        }
    }
}

// MARK: - Previews

struct TemplateRoomList_Previews: PreviewProvider {
    static let stateRenderer = MockTemplateRoomListScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true)
            .theme(.dark)
    }
}
