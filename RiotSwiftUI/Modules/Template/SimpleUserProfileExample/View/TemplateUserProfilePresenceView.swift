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
