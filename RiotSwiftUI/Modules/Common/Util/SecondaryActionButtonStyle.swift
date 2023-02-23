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

struct SecondaryActionButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    /// `theme.colors.accent` by default
    var customColor: Color?
    /// `theme.fonts.body` by default
    var font: Font?
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(12.0)
            .frame(maxWidth: .infinity)
            .foregroundColor(customColor ?? theme.colors.accent)
            .font(font ?? theme.fonts.body)
            .background(RoundedRectangle(cornerRadius: 8)
                .strokeBorder()
                .foregroundColor(customColor ?? theme.colors.accent))
            .opacity(opacity(when: configuration.isPressed))
    }
    
    private func opacity(when isPressed: Bool) -> CGFloat {
        guard isEnabled else { return 0.6 }
        return isPressed ? 0.6 : 1.0
    }
}

struct SecondaryActionButtonStyle_Previews: PreviewProvider {
    static var theme: ThemeSwiftUI = DefaultThemeSwiftUI()
    
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
            
            Button("Red BG") { }
                .buttonStyle(SecondaryActionButtonStyle(customColor: .red))
            
            Button { } label: {
                Text("Custom")
                    .foregroundColor(theme.colors.secondaryContent)
            }
            .buttonStyle(SecondaryActionButtonStyle(customColor: theme.colors.quarterlyContent))
        }
        .padding()
    }
}
