//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
