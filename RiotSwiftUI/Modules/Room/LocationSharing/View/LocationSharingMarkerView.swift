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

struct LocationSharingMarkerView<Content: View>: View {
    
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    let backgroundColor: Color
    @ViewBuilder var markerImage: Content
    
    var body: some View {
        ZStack {
            Rectangle()
                .rotation(Angle(degrees: 45))
                .fill(backgroundColor)
                .frame(width: 7, height: 7)
                .offset(x: 0, y: 21)
            markerImage
                .frame(width: 40, height: 40)
        }
    }
}

// MARK: - Previews

struct LocationSharingUserMarkerView_Previews: PreviewProvider {
    static var previews: some View {
        let avatarData = AvatarInput(mxContentUri: "",
                                     matrixItemId: "test",
                                     displayName: "Alice")
        VStack(alignment: .center, spacing: 15) {
            LocationSharingMarkerView(backgroundColor: .green) {
                AvatarImage(avatarData: avatarData, size: .medium)
                    .border()
            }
            LocationSharingMarkerView(backgroundColor: .green) {
                AvatarImage(avatarData: avatarData, size: .medium)
                    .border()
            }
        }
    }
}
