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
import DesignKit

@available(iOS 14.0, *)
struct AvatarImage: View {
    
    @Environment(\.theme) var theme: Theme
    @Environment(\.dependencies) var dependencies: DependencyContainer
    @StateObject var viewModel = AvatarViewModel()
    
    var mxContentUri: String?
    var matrixItemId: String
    var displayName: String?
    var size: AvatarSize
    
    var body: some View {
        Group {
            if let image = viewModel.viewState.avatarImage {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: CGFloat(size.rawValue), height: CGFloat(size.rawValue))
                    .clipShape(Circle())
            } else {
                Text(firstCharacterCapitalized(displayName))
                    .padding(4)
                    .frame(width: CGFloat(size.rawValue), height: CGFloat(size.rawValue))
                    .foregroundColor(.white)
                    .background(stableColor)
                    .clipShape(Circle())
                    // Make the text resizable (i.e. Make it large and then allow it to scale down)
                    .font(.system(size: 200))
                    .minimumScaleFactor(0.001)
            }
        }
        .onAppear {
            viewModel.inject(dependencies: dependencies)
            MXLog.debug("injected dependencies, \(dependencies)")
            viewModel.loadAvatar(
                mxContentUri: mxContentUri,
                avatarSize: size
            )
        }
    }
    
    private func firstCharacterCapitalized(_ string: String?) -> String {
        guard let character = string?.first else {
            return ""
        }
        return String(character).capitalized
    }
    
    /**
     Provides the same color each time for a specified matrixId.
     Same algorithm as in AvatarGenerator.
     */
    private var stableColor: Color {
        // Sum all characters
        let sum = matrixItemId.utf8
            .map({ UInt($0) })
            .reduce(0, +)
        // modulo the color count
        let index = Int(sum) % theme.avatarColors.count
        return Color(theme.avatarColors[index])
    }
}

@available(iOS 14.0, *)
extension AvatarImage {
    init(avatarData: AvatarInputType, size: AvatarSize) {
        self.init(
            mxContentUri: avatarData.mxContentUri,
            matrixItemId: avatarData.matrixItemId,
            displayName: avatarData.displayName,
            size: size
        )
    }
}

@available(iOS 14.0, *)
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
