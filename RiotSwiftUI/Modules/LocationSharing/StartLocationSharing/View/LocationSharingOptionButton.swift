// 
// Copyright 2022 New Vector Ltd
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

struct LocationSharingOptionButton<Content: View>: View {
    
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    let text: String
    let action: () -> (Void)
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
            LocationSharingOptionButton(text: VectorL10n.locationSharingStaticShareTitle) {
                
            } buttonIcon: {
                AvatarImage(avatarData: AvatarInput(mxContentUri: nil, matrixItemId: "Alice", displayName: "Alice"), size: .medium)
                    .border()
            }
            LocationSharingOptionButton(text: VectorL10n.locationSharingLiveShareTitle) {
                
            } buttonIcon: {
                Image(uiImage: Asset.Images.locationLiveIcon.image)
                    .resizable()
            }
            LocationSharingOptionButton(text: VectorL10n.locationSharingPinDropShareTitle) {
                
            } buttonIcon: {
                Image(uiImage: Asset.Images.locationPinIcon.image)
                    .resizable()
            }
        }
    }
}
