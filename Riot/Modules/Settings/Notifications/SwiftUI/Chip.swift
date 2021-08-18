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
struct Chip: View {
    
    @Environment(\.theme) var theme: Theme
    
    let titleKey: String
    let onClose: () -> Void
    
    var body: some View {
        HStack {
            Text(titleKey)
                .font(Font(theme.fonts.body))
                .lineLimit(1)
            Image(systemName: "xmark.circle.fill")
                .frame(width: 16, height: 16, alignment: .center)
                .onTapGesture(perform: onClose)
        }
        .padding(.leading, 12)
        .padding(.top, 6)
        .padding(.bottom, 6)
        .padding(.trailing, 8)
        .background(Color(theme.tintColor))
        .foregroundColor(Color.white)
        .cornerRadius(20)
        
    }
}

@available(iOS 14.0, *)
struct Chip_Previews: PreviewProvider {
    static var previews: some View {
        Chip(titleKey: "My great chip", onClose: { })
    }
}
