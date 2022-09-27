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

import DesignKit
import SwiftUI

struct AvatarImage: View {
    @Environment(\.theme) var theme: ThemeSwiftUI
    @Environment(\.dependencies) var dependencies: DependencyContainer
    @StateObject var viewModel = AvatarViewModel()
    
    var mxContentUri: String?
    var matrixItemId: String
    var displayName: String?
    var size: AvatarSize
    
    var body: some View {
        Group {
            switch viewModel.viewState {
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
            viewModel.inject(dependencies: dependencies)
            viewModel.loadAvatar(
                mxContentUri: mxContentUri,
                matrixItemId: matrixItemId,
                displayName: displayName,
                colorCount: theme.colors.namesAndAvatars.count,
                avatarSize: size
            )
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
            .addDependency(MockAvatarService.example)
        }
    }
}
