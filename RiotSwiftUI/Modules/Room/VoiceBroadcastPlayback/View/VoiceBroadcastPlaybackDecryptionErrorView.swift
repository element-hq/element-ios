// 
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct VoiceBroadcastPlaybackDecryptionErrorView: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                Image(uiImage: Asset.Images.errorIcon.image)
                    .frame(width: 40, height: 40)
                Text(VectorL10n.voiceBroadcastPlaybackUnableToDecrypt)
                    .multilineTextAlignment(.center)
                    .font(theme.fonts.caption1)
                    .foregroundColor(theme.colors.alert)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct VoiceBroadcastPlaybackDecryptionErrorView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceBroadcastPlaybackDecryptionErrorView()
    }
}
