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

@available(iOS 14.0, *)
struct LocationSharingOptionButtonIcon: View {
    
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    let fillColor: Color
    let image: UIImage
    
    var body: some View {
        ZStack {
            Circle()
                .fill(fillColor)
                .frame(width: 40, height: 40)
            Image(uiImage: image)
                .renderingMode(.template)
                .foregroundColor(Color.white)
        }
    }
}

@available(iOS 14.0, *)
struct LocationSharingOptionButtonIcon_Previews: PreviewProvider {
    static var previews: some View {
        LocationSharingOptionButtonIcon(fillColor: Color.green, image: Asset.Images.locationMarkerIcon.image)
    }
}
