//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct TemplateUserProfilePresenceView: View {
    let presence: TemplateUserProfilePresence
    
    var body: some View {
        HStack {
            Image(systemName: "circle.fill")
                .resizable()
                .frame(width: 8, height: 8)
            Text(presence.title)
                .font(.subheadline)
                .accessibilityIdentifier("presenceText")
        }
        .foregroundColor(foregroundColor)
        .padding(0)
    }
    
    // MARK: View Components
    
    private var foregroundColor: Color {
        switch presence {
        case .online:
            return .green
        case .idle:
            return .orange
        case .offline:
            return .gray
        }
    }
}

// MARK: - Previews

struct TemplateUserProfilePresenceView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading) {
            Text("Presence")
            ForEach(TemplateUserProfilePresence.allCases) { presence in
                TemplateUserProfilePresenceView(presence: presence)
            }
        }
    }
}
