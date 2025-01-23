//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import DesignKit
import SwiftUI

struct SpaceAvatarImage: View {
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
                Text(String(firstCharacter))
                    .padding(10)
                    .frame(width: CGFloat(size.rawValue), height: CGFloat(size.rawValue))
                    .foregroundColor(.white)
                    .background(theme.colors.namesAndAvatars[colorIndex])
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    // Make the text resizable (i.e. Make it large and then allow it to scale down)
                    .font(.system(size: 200))
                    .minimumScaleFactor(0.001)
            case .avatar(let image):
                Image(uiImage: image)
                    .resizable()
                    .frame(width: CGFloat(size.rawValue), height: CGFloat(size.rawValue))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .onChange(of: displayName) { value in
            guard case .placeholder = avatar else { return }
            viewModel.loadAvatar(mxContentUri: mxContentUri,
                                 matrixItemId: matrixItemId,
                                 displayName: value,
                                 colorCount: theme.colors.namesAndAvatars.count,
                                 avatarSize: size) { newState in
                avatar = newState
            }
        }
        .onAppear {
            avatar = viewModel.placeholderAvatar(matrixItemId: matrixItemId,
                                                    displayName: displayName,
                                                    colorCount: theme.colors.namesAndAvatars.count)
            viewModel.loadAvatar(mxContentUri: mxContentUri,
                                 matrixItemId: matrixItemId,
                                 displayName: displayName,
                                 colorCount: theme.colors.namesAndAvatars.count,
                                 avatarSize: size) { newState in
                avatar = newState
            }
        }
    }
}

extension SpaceAvatarImage {
    init(avatarData: AvatarInputProtocol, size: AvatarSize) {
        self.init(
            mxContentUri: avatarData.mxContentUri,
            matrixItemId: avatarData.matrixItemId,
            displayName: avatarData.displayName,
            size: size
        )
    }
}

struct LiveAvatarImage_Previews: PreviewProvider {
    static let mxContentUri = "fakeUri"
    static let name = "Alice"
    static var previews: some View {
        Group {
            HStack {
                VStack(alignment: .center, spacing: 20) {
                    SpaceAvatarImage(avatarData: MockAvatarInput.example, size: .xSmall)
                    SpaceAvatarImage(avatarData: MockAvatarInput.example, size: .medium)
                    SpaceAvatarImage(avatarData: MockAvatarInput.example, size: .xLarge)
                }
                VStack(alignment: .center, spacing: 20) {
                    SpaceAvatarImage(mxContentUri: nil, matrixItemId: name, displayName: name, size: .xSmall)
                    SpaceAvatarImage(mxContentUri: nil, matrixItemId: name, displayName: name, size: .medium)
                    SpaceAvatarImage(mxContentUri: nil, matrixItemId: name, displayName: name, size: .xLarge)
                }
            }
            .environmentObject(AvatarViewModel.withMockedServices())
        }
    }
}
