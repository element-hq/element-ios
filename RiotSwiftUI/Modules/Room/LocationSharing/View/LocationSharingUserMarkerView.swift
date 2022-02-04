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
    
    // MARK: Public
    
    let avatarData: AvatarInputProtocol
    
    var body: some View {
        ZStack {
            Image(uiImage: Asset.Images.locationUserMarker.image)
            AvatarImage(avatarData: avatarData, size: .large)
                .offset(y: -1.5)
        }
        .background(ViewFrameReader(frame: $frame))
        .padding(.bottom, frame.height)
        .accentColor(theme.colors.accent)
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct LocationSharingUserMarkerView_Previews: PreviewProvider {
    static var previews: some View {
        let avatarData = AvatarInput(mxContentUri: "",
                                     matrixItemId: "",
                                     displayName: "Alice")
        
        LocationSharingUserMarkerView(avatarData: avatarData)
    }
}
