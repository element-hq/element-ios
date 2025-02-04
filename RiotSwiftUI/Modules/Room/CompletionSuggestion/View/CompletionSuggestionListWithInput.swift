//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct CompletionSuggestionListWithInputViewModel {
    let listViewModel: CompletionSuggestionViewModel
    let callback: (String) -> Void
}

struct CompletionSuggestionListWithInput: View {
    // MARK: - Properties
    
    // MARK: Private
    
    // MARK: Public
    
    var viewModel: CompletionSuggestionListWithInputViewModel
    @State private var inputText = ""
    
    var body: some View {
        VStack(spacing: 0.0) {
            CompletionSuggestionList(viewModel: viewModel.listViewModel.context)
            TextField("Search for user/command", text: $inputText)
                .background(Color.white)
                .onChange(of: inputText, perform: viewModel.callback)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding([.leading, .trailing])
                .onAppear {
                    inputText = "@-" // Make the list show all available user mock results
                }
        }
    }
}

// MARK: - Previews

struct CompletionSuggestionListWithInput_Previews: PreviewProvider {
    static let stateRenderer = MockCompletionSuggestionScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
