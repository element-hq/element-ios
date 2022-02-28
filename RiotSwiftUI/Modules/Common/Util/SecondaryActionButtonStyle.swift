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
struct SecondaryActionButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    
    var customColor: Color? = nil
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(12.0)
            .frame(maxWidth: .infinity)
            .foregroundColor(strokeColor(configuration.isPressed))
            .font(theme.fonts.body)
            .background(RoundedRectangle(cornerRadius: 8)
                            .strokeBorder()
                            .foregroundColor(strokeColor(configuration.isPressed)))
            .opacity(isEnabled ? 1.0 : 0.6)
    }
    
    func strokeColor(_ isPressed: Bool) -> Color {
        if let customColor = customColor {
            return customColor
        }
        
        return isPressed ? theme.colors.accent.opacity(0.6) : theme.colors.accent
    }
}

@available(iOS 14.0, *)
struct SecondaryActionButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            buttonGroup
        }.theme(.light).preferredColorScheme(.light)
        Group {
            buttonGroup
        }.theme(.dark).preferredColorScheme(.dark)
    }
    
    static var buttonGroup: some View {
        VStack {
            Button("Enabled") { }
                .buttonStyle(SecondaryActionButtonStyle())
            
            Button("Disabled") { }
                .buttonStyle(SecondaryActionButtonStyle())
                .disabled(true)
            
            Button { } label: {
                Text("Clear BG")
                    .foregroundColor(.red)
            }
            .buttonStyle(SecondaryActionButtonStyle(customColor: .clear))
            
            Button("Red BG") { }
            .buttonStyle(SecondaryActionButtonStyle(customColor: .red))
        }
        .padding()
    }
}
