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
struct TemplateRoomChat: View {
    
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    @ObservedObject var viewModel: TemplateRoomChatViewModel.Context
    
    var body: some View {
        VStack {
            if viewModel.viewState.bubbles.isEmpty {
                VStack{
                    Text("No messages")
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView{
                    LazyVStack {
                        ForEach(viewModel.viewState.bubbles) { bubble in
                            TemplateRoomChatBubbleView(bubble: bubble)
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                }
                .frame(maxHeight: .infinity)
            }
            
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
            .animation(.easeOut(duration: 0.25))
            .transition(.move(edge: .trailing))
            .padding(.horizontal)
            
        }
        .navigationTitle(viewModel.viewState.roomName ?? "Chat")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(VectorL10n.done) {
                    viewModel.send(viewAction: .cancel)
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button(VectorL10n.cancel) {
                    viewModel.send(viewAction: .cancel)
                }
            }
        }
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct TemplateRoomChat_Previews: PreviewProvider {
    static var previews: some View {
        MockTemplateRoomChatScreenState.screenGroup(addNavigation: true)
    }
}
