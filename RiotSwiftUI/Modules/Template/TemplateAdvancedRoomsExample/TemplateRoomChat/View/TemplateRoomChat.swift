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
    
    @ObservedObject var viewModel: TemplateRoomChatViewModel
    
    var body: some View {
        VStack {
            LazyVStack {
                
            }.frame(maxHeight: .infinity)
            
            HStack {
                TextField(VectorL10n.roomMessageShortPlaceholder, text: $viewModel.input.messageInput)
                    .textFieldStyle(BorderedInputFieldStyle())
                Button(action: {
                    
                }, label: {
                    Image(uiImage: Asset.Images.sendIcon.image)
                })
            }
            .padding(.horizontal)
            
        }
        .navigationTitle("Chat")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(VectorL10n.done) {
                    viewModel.process(viewAction: .cancel)
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button(VectorL10n.cancel) {
                    viewModel.process(viewAction: .cancel)
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
