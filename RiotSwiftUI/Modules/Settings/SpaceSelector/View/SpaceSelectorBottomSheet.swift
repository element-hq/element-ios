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

struct SpaceSelectorBottomSheet: View {

    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    @ObservedObject var viewModel: SpaceSelectorBottomSheetViewModel.Context
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack {
                    ForEach(viewModel.viewState.items) { item in
                        SpaceSelectorBottomSheetListRow(avatar: item.avatar, displayName: item.displayName)
                            .onTapGesture {
                                viewModel.send(viewAction: .spaceSelected(item))
                            }
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .background(theme.colors.background.edgesIgnoringSafeArea(.all))
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Previews

struct SpaceSelectorBottomSheet_Previews: PreviewProvider {
    static let stateRenderer = MockSpaceSelectorBottomSheetScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
