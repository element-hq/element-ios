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

struct PollEditFormTypePicker: View {
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    @Binding var selectedType: EditFormPollType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16.0) {
            Text(VectorL10n.pollEditFormPollType)
                .font(theme.fonts.title3SB)
                .foregroundColor(theme.colors.primaryContent)
            PollEditFormTypeButton(type: .disclosed, selectedType: $selectedType)
            PollEditFormTypeButton(type: .undisclosed, selectedType: $selectedType)
        }
    }
}

private struct PollEditFormTypeButton: View {
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    let type: EditFormPollType
    @Binding var selectedType: EditFormPollType
    
    var body: some View {
        Button {
            selectedType = type
        } label: {
            HStack(alignment: .top, spacing: 8.0) {
                Image(uiImage: selectionImage)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(theme.fonts.body)
                        .foregroundColor(theme.colors.primaryContent)
                    Text(description)
                        .font(theme.fonts.footnote)
                        .foregroundColor(theme.colors.secondaryContent)
                }
            }
        }
    }
    
    private var title: String {
        switch type {
        case .disclosed:
            return VectorL10n.pollEditFormPollTypeOpen
        case .undisclosed:
            return VectorL10n.pollEditFormPollTypeClosed
        }
    }
    
    private var description: String {
        switch type {
        case .disclosed:
            return VectorL10n.pollEditFormPollTypeOpenDescription
        case .undisclosed:
            return VectorL10n.pollEditFormPollTypeClosedDescription
        }
    }
    
    private var selectionImage: UIImage {
        if type == selectedType {
            return Asset.Images.pollTypeCheckboxSelected.image
        } else {
            return Asset.Images.pollTypeCheckboxDefault.image
        }
    }
}

struct PollEditFormTypePicker_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PollEditFormTypePicker(selectedType: Binding.constant(.disclosed))
            PollEditFormTypePicker(selectedType: Binding.constant(.undisclosed))
        }
    }
}
