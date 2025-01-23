//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct LocationSharingOptionButton<Content: View>: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    let text: String
    let action: () -> Void
    @ViewBuilder var buttonIcon: Content
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 18) {
                buttonIcon
                    .frame(width: 40, height: 40)
                Text(text)
                    .font(theme.fonts.body)
                    .foregroundColor(theme.colors.primaryContent)
            }
        }
    }
}

struct LocationSharingOptionButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading) {
            LocationSharingOptionButton(text: VectorL10n.locationSharingStaticShareTitle) { } buttonIcon: {
                AvatarImage(avatarData: AvatarInput(mxContentUri: nil, matrixItemId: "Alice", displayName: "Alice"), size: .medium)
                    .border()
            }
            LocationSharingOptionButton(text: VectorL10n.locationSharingLiveShareTitle) { } buttonIcon: {
                Image(uiImage: Asset.Images.locationLiveIcon.image)
                    .resizable()
            }
            LocationSharingOptionButton(text: VectorL10n.locationSharingPinDropShareTitle) { } buttonIcon: {
                Image(uiImage: Asset.Images.locationPinIcon.image)
                    .resizable()
            }
        }
    }
}
