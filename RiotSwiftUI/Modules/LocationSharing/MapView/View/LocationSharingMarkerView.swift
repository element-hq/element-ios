//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct LocationSharingMarkerView<Content: View>: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    let backgroundColor: Color
    @ViewBuilder var markerImage: Content
    
    var body: some View {
        ZStack {
            Rectangle()
                .rotation(Angle(degrees: 45))
                .fill(backgroundColor)
                .frame(width: 7, height: 7)
                .offset(x: 0, y: 21)
            markerImage
                .frame(width: 40, height: 40)
        }
    }
}

// MARK: - Previews

struct LocationSharingUserMarkerView_Previews: PreviewProvider {
    static var previews: some View {
        let avatarData = AvatarInput(mxContentUri: "",
                                     matrixItemId: "test",
                                     displayName: "Alice")
        VStack(alignment: .center, spacing: 15) {
            LocationSharingMarkerView(backgroundColor: .green) {
                AvatarImage(avatarData: avatarData, size: .medium)
                    .border()
            }
            LocationSharingMarkerView(backgroundColor: .green) {
                AvatarImage(avatarData: avatarData, size: .medium)
                    .border()
            }
        }
    }
}
