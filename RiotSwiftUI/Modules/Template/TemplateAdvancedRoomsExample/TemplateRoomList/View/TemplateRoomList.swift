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

struct TemplateRoomList: View {
    
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
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
            ScrollView{
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
