//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct PrimaryActionButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    /// `theme.colors.accent` by default
    var customColor: Color?
    /// `theme.colors.body` by default
    var font: Font?
    
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
            .font(font ?? theme.fonts.body)
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
