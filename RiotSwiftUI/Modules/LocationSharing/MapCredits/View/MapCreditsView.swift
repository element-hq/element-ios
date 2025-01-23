//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct MapCreditsView: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    var action: (() -> Void)?
    
    var body: some View {
        HStack {
            Spacer()
            Button {
                action?()
            } label: {
                Text(VectorL10n.locationSharingMapCreditsTitle)
                    .font(theme.fonts.footnote)
                    .foregroundColor(theme.colors.accent)
            }
            .padding(.horizontal)
        }
    }
}

struct MapCreditsView_Previews: PreviewProvider {
    static var previews: some View {
        MapCreditsView()
    }
}
