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

@available(iOS 14.0, *)
struct LocationSharingUserMarkerView: View {
    
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    @State private var frame: CGRect = .zero
    
    private var usernameColorGenerator: UserNameColorGenerator {
        let usernameColorGenerator = UserNameColorGenerator()
        let theme = ThemeService.shared().theme
        usernameColorGenerator.defaultColor = theme.textPrimaryColor
        usernameColorGenerator.userNameColors = theme.userNameColors
        return usernameColorGenerator
    }
    
    // MARK: Public
    
    let isMarker: Bool
    let avatarData: AvatarInputProtocol
    
    var body: some View {
        let fillColor: Color = Color(usernameColorGenerator.color(from:avatarData.matrixItemId))
        ZStack {
            Circle()
                .fill(fillColor)
                .frame(width: 40, height: 40)
            if isMarker {
                Rectangle()
                    .rotation(Angle(degrees: 45))
                    .fill(fillColor)
                    .frame(width: 7, height: 7)
                    .offset(x: 0, y: 19)
            }
            AvatarImage(avatarData: avatarData, size: .small)
        }
        .background(ViewFrameReader(frame: $frame))
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct LocationSharingUserMarkerView_Previews: PreviewProvider {
    static var previews: some View {
        let avatarData = AvatarInput(mxContentUri: "",
                                     matrixItemId: "test",
                                     displayName: "Alice")
        VStack(alignment: .center, spacing: 15) {
            LocationSharingUserMarkerView(isMarker: true, avatarData: avatarData)
            LocationSharingUserMarkerView(isMarker: false, avatarData: avatarData)
        }
    }
}
