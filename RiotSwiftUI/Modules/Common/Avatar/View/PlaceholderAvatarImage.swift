//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// A reusable view that will show a standard placeholder avatar with the
/// supplied character and colour index for the `namesAndAvatars` color array.
///
/// This view has a forced 1:1 aspect ratio but will appear very large until a `.frame`
/// modifier is applied.
struct PlaceholderAvatarImage: View {
    // MARK: - Private
    
    @Environment(\.theme) private var theme
    
    // MARK: - Public
    
    let firstCharacter: Character
    let colorIndex: Int
    
    // MARK: - Views
    
    var body: some View {
        ZStack {
            theme.colors.namesAndAvatars[colorIndex]
            
            Text(String(firstCharacter))
                .padding(4)
                .foregroundColor(.white)
                // Make the text resizable (i.e. Make it large and then allow it to scale down)
                .font(.system(size: 200))
                .minimumScaleFactor(0.001)
        }
        .aspectRatio(1, contentMode: .fill)
    }
}

struct Previews_TemplateAvatarImage_Previews: PreviewProvider {
    static var previews: some View {
        PlaceholderAvatarImage(firstCharacter: "X", colorIndex: 1)
            .clipShape(Circle())
            .frame(width: 150, height: 100)
    }
}
