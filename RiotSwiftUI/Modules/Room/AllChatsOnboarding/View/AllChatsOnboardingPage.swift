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

struct AllChatsOnboardingPage: View {
    // MARK: - Properties
    
    let image: UIImage
    let title: String
    let message: String
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    var body: some View {
        VStack {
            Spacer()
            Image(uiImage: image)
            Spacer()
            Text(title)
                .font(theme.fonts.title2B)
                .foregroundColor(theme.colors.primaryContent)
                .padding(.bottom, 16)
            Text(message)
                .multilineTextAlignment(.center)
                .font(theme.fonts.callout)
                .foregroundColor(theme.colors.primaryContent)
            Spacer()
        }
        .padding(.horizontal)
    }
}

// MARK: - Previews

struct AllChatsOnboardingPage_Previews: PreviewProvider {
    static var previews: some View {
        preview.theme(.light).preferredColorScheme(.light)
        preview.theme(.dark).preferredColorScheme(.dark)
    }
    
    private static var preview: some View {
        AllChatsOnboardingPage(image: Asset.Images.allChatsOnboarding1.image,
                               title: VectorL10n.allChatsOnboardingPageTitle1,
                               message: VectorL10n.allChatsOnboardingPageMessage1)
    }
}
