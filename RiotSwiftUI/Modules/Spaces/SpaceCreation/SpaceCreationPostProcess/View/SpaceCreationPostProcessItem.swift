//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct SpaceCreationPostProcessItem: View {
    // MARK: - Properties
    
    let title: String
    let state: SpaceCreationPostProcessTaskState
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    private var tintColor: Color {
        switch state {
        case .none:
            return theme.colors.quinaryContent
        case .started:
            return theme.colors.primaryContent
        case .success:
            return theme.colors.tertiaryContent
        case .failure:
            return theme.colors.alert
        }
    }
    
    // MARK: Public
    
    var body: some View {
        HStack {
            switch state {
            case .none:
                Image(systemName: "circle").renderingMode(.template).foregroundColor(theme.colors.tertiaryContent)
            case .started:
                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: theme.colors.secondaryContent)).scaleEffect(0.9, anchor: .center)
                Spacer().frame(width: 6)
            case .success:
                Image(systemName: "checkmark.circle.fill").renderingMode(.template).foregroundColor(theme.colors.tertiaryContent)
            case .failure:
                Image(systemName: "exclamationmark.circle.fill").renderingMode(.template).foregroundColor(theme.colors.alert)
            }
            Text(title)
                .font(theme.fonts.callout)
                .foregroundColor(state == .started ? theme.colors.primaryContent : theme.colors.tertiaryContent)
        }
        .opacity(state == .none ? 0.5 : 1)
        .animation(.easeOut(duration: 0.2), value: state)
    }
}

// MARK: - Previews

struct SpaceCreationPostProcessItem_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack(alignment: .leading, spacing: 20) {
                SpaceCreationPostProcessItem(title: "failed task", state: .failure)
                SpaceCreationPostProcessItem(title: "not started", state: .none)
                SpaceCreationPostProcessItem(title: "on going task ", state: .started)
                SpaceCreationPostProcessItem(title: "succesful task", state: .success)
            }
            VStack(alignment: .leading, spacing: 20) {
                SpaceCreationPostProcessItem(title: "failed task", state: .failure)
                SpaceCreationPostProcessItem(title: "not started", state: .none)
                SpaceCreationPostProcessItem(title: "on going task ", state: .started)
                SpaceCreationPostProcessItem(title: "succesful task", state: .success)
            }.theme(.dark).preferredColorScheme(.dark)
        }
        .padding()
    }
}
