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

/// A reusable view that will show a standard placeholder avatar with the
/// supplied character and colour index for the `namesAndAvatars` color array.
///
/// This view has a forced 1:1 aspect ratio but will appear very large until a `.frame`
/// modifier is applied.
struct PlaceholderAvatarImage: View {
    // MARK: - Private
    
    @Environment(\.theme) private var theme
    
    // MARK: - Public
    
    let firstCharacter: Character
    let colorIndex: Int
    
    // MARK: - Views
    
    var body: some View {
        ZStack {
            theme.colors.namesAndAvatars[colorIndex]
            
            Text(String(firstCharacter))
                .padding(4)
                .foregroundColor(.white)
                // Make the text resizable (i.e. Make it large and then allow it to scale down)
                .font(.system(size: 200))
                .minimumScaleFactor(0.001)
        }
        .aspectRatio(1, contentMode: .fill)
    }
}

struct Previews_TemplateAvatarImage_Previews: PreviewProvider {
    static var previews: some View {
        PlaceholderAvatarImage(firstCharacter: "X", colorIndex: 1)
            .clipShape(Circle())
            .frame(width: 150, height: 100)
    }
}
