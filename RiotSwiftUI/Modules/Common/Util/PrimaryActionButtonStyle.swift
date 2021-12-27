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
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    
    var customColor: Color? = nil
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(12.0)
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
            .font(theme.fonts.body)
            .background(backgroundColor(configuration.isPressed))
            .opacity(isEnabled ? 1.0 : 0.6)
            .cornerRadius(8.0)
    }
    
    func backgroundColor(_ isPressed: Bool) -> Color {
        if let customColor = customColor {
            return customColor
        }
        
        return isPressed ? theme.colors.accent.opacity(0.6) : theme.colors.accent
    }
}

@available(iOS 14.0, *)
struct PrimaryActionButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
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
}
