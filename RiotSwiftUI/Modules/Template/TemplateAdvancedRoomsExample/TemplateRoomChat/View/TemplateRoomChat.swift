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
import Combine

struct TemplateRoomChat: View {
    
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    @ObservedObject var viewModel: TemplateRoomChatViewModel.Context
    var presentedModally = false
    
    var body: some View {
        VStack {
            VStack{
                roomContent
            }.frame(maxHeight: .infinity)
            
            HStack {
                TextField(VectorL10n.roomMessageShortPlaceholder, text: $viewModel.messageInput)
                    .textFieldStyle(BorderedInputFieldStyle())
                if viewModel.viewState.sendButtonEnabled {
                    Button(action: {
                        viewModel.send(viewAction: .sendMessage)
                    }, label: {
                        Image(uiImage: Asset.Images.sendIcon.image)
                    })
                }
            }
            // When displaying/hiding the send button slide it on/off from the right side
            .animation(.easeOut(duration: 0.25))
            .transition(.move(edge: .trailing))
            .padding()
            
        }
        .background(theme.colors.background)
        .navigationTitle(viewModel.viewState.roomName ?? "Chat")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                trailingToolBarButton
            }
        }
    }
    
    @ViewBuilder
    private var roomContent: some View {
        if case .notInitialized = viewModel.viewState.roomInitializationStatus {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: theme.colors.primaryContent))
                .accessibility(identifier: "loadingProgress")
        } else if case .failedToInitialize = viewModel.viewState.roomInitializationStatus {
            Text("Sorry, We failed to load the room.")
                .foregroundColor(theme.colors.primaryContent)
                .accessibility(identifier: "errorMessage")
        } else if viewModel.viewState.bubbles.isEmpty {
            Text("There are no messages in this room yet.")
                .foregroundColor(theme.colors.primaryContent)
                .accessibility(identifier: "errorMessage")
        } else {
            bubbleList
        }
    }
    
    private var bubbleList: some View {
        ScrollViewReader { reader in
            ScrollView{
                LazyVStack {
                    ForEach(viewModel.viewState.bubbles) { bubble in
                        TemplateRoomChatBubbleView(bubble: bubble)
                            .id(bubble.id)
                    }
                }
                .onAppear{
                    guard let lastBubbleId = viewModel.viewState.bubbles.last?.id
                    else { return }
                    reader.scrollTo(lastBubbleId, anchor: .bottom)
                }
                .onChange(of: itemCount) { _ in
                    guard let lastBubbleId = viewModel.viewState.bubbles.last?.id
                    else { return }
                    reader.scrollTo(lastBubbleId, anchor: .bottom)
                }
                // When the scroll content takes less than the screen space align at the top
                .frame(maxHeight: .infinity, alignment: .top)
            }
        }
    }
    
    @ViewBuilder
    private var trailingToolBarButton: some View {
        if presentedModally {
            Button(VectorL10n.done) {
                viewModel.send(viewAction: .done)
            }
        }
    }
    
    private var itemCount: Int {
        return viewModel.viewState
            .bubbles
            .map(\.items)
            .map(\.count)
            .reduce(0, +)
    }
}

// MARK: - Previews

struct TemplateRoomChat_Previews: PreviewProvider {
    static let stateRenderer = MockTemplateRoomChatScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true)
    }
}
