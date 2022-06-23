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

struct PrimaryActionButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    
    var customColor: Color? = nil
    
    private var fontColor: Color {
        // Always white unless disabled with a dark theme.
        .white.opacity(theme.isDark && !isEnabled ? 0.3 : 1.0)
    }
    
    private var backgroundColor: Color {
        customColor ?? theme.colors.accent
    }
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(12.0)
            .frame(maxWidth: .infinity)
            .foregroundColor(fontColor)
            .font(theme.fonts.body)
            .background(backgroundColor.opacity(backgroundOpacity(when: configuration.isPressed)))
            .cornerRadius(8.0)
    }
    
    func backgroundOpacity(when isPressed: Bool) -> CGFloat {
        guard isEnabled else { return 0.3 }
        return isPressed ? 0.6 : 1.0
    }
}

struct PrimaryActionButtonStyle_Previews: PreviewProvider {
    static var buttons: some View {
        Group {
            VStack {
                Button("Enabled") { }
                    .buttonStyle(PrimaryActionButtonStyle())
                
                Button("Disabled") { }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .disabled(true)
                
                Button { } label: {
                    Text("Clear BG")
                        .foregroundColor(.red)
                }
                .buttonStyle(PrimaryActionButtonStyle(customColor: .clear))
                
                Button("Red BG") { }
                .buttonStyle(PrimaryActionButtonStyle(customColor: .red))
            }
            .padding()
        }
    }
    
    static var previews: some View {
        buttons
            .theme(.light).preferredColorScheme(.light)
        buttons
            .theme(.dark).preferredColorScheme(.dark)
    }
}
