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
struct PrimaryActionButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    var enabled: Bool = false
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(12.0)
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
            .font(theme.fonts.body)
            .background(configuration.isPressed ? theme.colors.accent.opacity(0.6) : theme.colors.accent)
            .opacity(enabled ? 1.0 : 0.6)
            .cornerRadius(8.0)
    }
}

@available(iOS 14.0, *)
struct PrimaryActionButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack {
                Button("Enabled") { }
                    .buttonStyle(PrimaryActionButtonStyle(enabled: true))
                
                Button("Disabled") { }
                    .buttonStyle(PrimaryActionButtonStyle(enabled: false))
                    .disabled(true)
            }
            .padding()
        }
    }
}
