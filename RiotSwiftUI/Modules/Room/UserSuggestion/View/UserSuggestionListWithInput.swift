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

struct UserSuggestionListWithInputViewModel {
    let listViewModel: UserSuggestionViewModel
    let callback: (String) -> Void
}

struct UserSuggestionListWithInput: View {
    // MARK: - Properties
    
    // MARK: Private
    
    // MARK: Public
    
    var viewModel: UserSuggestionListWithInputViewModel
    @State private var inputText = ""
    
    var body: some View {
        VStack(spacing: 0.0) {
            UserSuggestionList(viewModel: viewModel.listViewModel.context)
            TextField("Search for user", text: $inputText)
                .background(Color.white)
                .onChange(of: inputText, perform: viewModel.callback)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding([.leading, .trailing])
                .onAppear {
                    inputText = "@-" // Make the list show all available mock results
                }
        }
    }
}

// MARK: - Previews

struct UserSuggestionListWithInput_Previews: PreviewProvider {
    static let stateRenderer = MockUserSuggestionScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
