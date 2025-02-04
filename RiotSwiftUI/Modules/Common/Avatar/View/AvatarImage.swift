//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import DesignKit
import SwiftUI

struct AvatarImage: View {
    @Environment(\.theme) var theme: ThemeSwiftUI
    @EnvironmentObject var viewModel: AvatarViewModel
    
    var mxContentUri: String?
    var matrixItemId: String
    var displayName: String?
    var size: AvatarSize
    
    @State private var avatar: AvatarViewState = .empty
    
    var body: some View {
        Group {
            switch avatar {
            case .empty:
                ProgressView()
            case .placeholder(let firstCharacter, let colorIndex):
                PlaceholderAvatarImage(firstCharacter: firstCharacter,
                                       colorIndex: colorIndex)
            case .avatar(let image):
                Image(uiImage: image)
                    .resizable()
            }
        }
        .frame(maxWidth: CGFloat(size.rawValue), maxHeight: CGFloat(size.rawValue))
        .clipShape(Circle())
        .onAppear {
            avatar = viewModel.placeholderAvatar(matrixItemId: matrixItemId,
                                                 displayName: displayName,
                                                 colorCount: theme.colors.namesAndAvatars.count)
            viewModel.loadAvatar(mxContentUri: mxContentUri,
                                 matrixItemId: matrixItemId,
                                 displayName: displayName,
                                 colorCount: theme.colors.namesAndAvatars.count,
                                 avatarSize: size ) { newState in
                avatar = newState
            }
        }
    }
}

extension AvatarImage {
    init(avatarData: AvatarInputProtocol, size: AvatarSize) {
        self.init(
            mxContentUri: avatarData.mxContentUri,
            matrixItemId: avatarData.matrixItemId,
            displayName: avatarData.displayName,
            size: size
        )
    }
}

extension AvatarImage {
    func border(color: Color) -> some View {
        modifier(BorderModifier(color: color, borderWidth: 3, shape: Circle()))
    }
    
    /// Use display name color as border color by default
    func border() -> some View {
        let borderColor = theme.userColor(for: matrixItemId)
        return border(color: borderColor)
    }
}

struct AvatarImage_Previews: PreviewProvider {
    static let mxContentUri = "fakeUri"
    static let name = "Alice"
    static var previews: some View {
        Group {
            HStack {
                VStack(alignment: .center, spacing: 20) {
                    AvatarImage(avatarData: MockAvatarInput.example, size: .xSmall)
                    AvatarImage(avatarData: MockAvatarInput.example, size: .medium)
                    AvatarImage(avatarData: MockAvatarInput.example, size: .xLarge)
                }
                VStack(alignment: .center, spacing: 20) {
                    AvatarImage(mxContentUri: nil, matrixItemId: name, displayName: name, size: .xSmall)
                    AvatarImage(mxContentUri: nil, matrixItemId: name, displayName: name, size: .medium)
                    AvatarImage(mxContentUri: nil, matrixItemId: name, displayName: name, size: .xLarge)
                }
            }
            .environmentObject(AvatarViewModel.withMockedServices())
        }
    }
}
