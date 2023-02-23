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

struct UserSessionOverviewToggleCell: View {
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    let title: String
    let message: String?
    let isOn: Bool
    let isEnabled: Bool
    var onBackgroundTap: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: {
                guard isEnabled else { return }
                onBackgroundTap?()
            }) {
                VStack(spacing: 0) {
                    SeparatorLine()
                    Toggle(isOn: .constant(isOn)) {
                        Text(title)
                            .font(theme.fonts.body)
                            .foregroundColor(theme.colors.primaryContent)
                            .opacity(isEnabled ? 1 : 0.3)
                    }
                    .disabled(!isEnabled)
                    .allowsHitTesting(false)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .accessibilityIdentifier("UserSessionOverviewToggleCell")
                    SeparatorLine()
                }
                .background(theme.colors.background)
            }
            .disabled(!isEnabled)
            if let message = message {
                Text(message)
                    .multilineTextAlignment(.leading)
                    .font(theme.fonts.footnote)
                    .foregroundColor(theme.colors.secondaryContent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
            }
        }
    }
}

struct UserSessionOverviewToggleCell_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            preview
                .theme(.light)
                .preferredColorScheme(.light)
            preview
                .theme(.dark)
                .preferredColorScheme(.dark)
        }
    }
    
    static var preview: some View {
        VStack {
            UserSessionOverviewToggleCell(title: "Title", message: nil, isOn: true, isEnabled: true)
            UserSessionOverviewToggleCell(title: "Title", message: nil, isOn: false, isEnabled: true)
            UserSessionOverviewToggleCell(title: "Title", message: "some very long message text in order to test the multine alignment", isOn: true, isEnabled: true)
            UserSessionOverviewToggleCell(title: "Title", message: nil, isOn: true, isEnabled: false)
            UserSessionOverviewToggleCell(title: "Title", message: nil, isOn: false, isEnabled: false)
            UserSessionOverviewToggleCell(title: "Title", message: "some very long message text in order to test the multine alignment", isOn: true, isEnabled: false)
        }
    }
}
