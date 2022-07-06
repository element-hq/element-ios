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

struct OnboardingIconImage: View {
    
    @Environment(\.theme) private var theme
    
    let image: ImageAsset
    
    var body: some View {
        Image(image.name)
            .resizable()
            .renderingMode(.template)
            .foregroundColor(theme.colors.accent)
            .frame(width: OnboardingMetrics.iconSize, height: OnboardingMetrics.iconSize)
            .background(Circle().foregroundColor(.white).padding(2))
            .accessibilityHidden(true)
    }
}

// MARK: - Previews

struct OnboardingIconImage_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingIconImage(image: Asset.Images.authenticationEmailIcon)
    }
}
